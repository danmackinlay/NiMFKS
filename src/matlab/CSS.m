classdef CSS < handle
    properties
        NMF_features
        Activations
        Cost
        Synthesis_method
        Synthesis
    end
    
    methods
        function obj = CSS(varargin)
            if nargin == 2
                obj.NMF_features = varargin{1};
                obj.Synthesis_method = varargin{2};
            end
        end
    end
    
    methods
        function obj = nmf(obj, corpus_sound, target_sound, varargin)
            if( nargin == 4  )
                pct_prune = varargin{1}
            else
                pct_prune = 1
            end
            nmf_alg = obj.NMF_features.Algorithm;
            target_spect = abs(target_sound.Features.STFT.S);
            corpus_spect = abs(corpus_sound.Features.STFT.S);
            [corpus_spect, pruned_frames, frames_to_keep] = prune_corpus( target_spect, corpus_spect, pct_prune );
            
            switch nmf_alg
                case 'Euclidean'
                    if length(fieldnames(obj.NMF_features)) > 1
                        [H, obj.Cost] = nmf_euclidean(target_spect, corpus_spect, obj.NMF_features);
                    else
                        [H, obj.Cost] = nmf_euclidean(target_spect, corpus_spect);
                    end
                case 'Divergence'
                    if length(fieldnames(obj.NMF_features)) > 1
                        [H, obj.Cost] = nmf_divergence(target_spect, corpus_spect, obj.NMF_features);
                    else
                        [H, obj.Cost] = nmf_divergence(target_spect, corpus_spect);
                    end
                case 'Sparse NMF'                 
                    if length(fieldnames(obj.NMF_features)) > 1
                        [~, H, deleted, obj.Cost] = SA_B_NMF(target_spect, corpus_spect, 5, obj.NMF_features);
                    else
                        [~, H, deleted, obj.Cost] = SA_B_NMF(target_spect, corpus_spect, 5 );
                    end
                    
                    H( deleted, : ) = 0;
                    obj.Activations = H;
            end
            
            if size( frames_to_keep ) > 0
                tmp = zeros( size( corpus_sound.Features.STFT.S,2 ), size( target_spect,2 ) );
                for i = 1:length( frames_to_keep )
                    tmp(frames_to_keep(i), :) = H(i,:);
                end
                H = tmp;
            end
%             H( pruned_frames, : ) = 0;
%             % Pad activations to size of corpus frames
%             % since pruned frames maximum can be < size of corpus
%             H( setdiff( 1:( size( corpus_spect, 2 ) + length( pruned_frames ) ), 1:size( H, 1 ) ), : ) = 0;
            obj.Activations = H;
        end
        
        function obj = synthesize(obj, corpus_sound)
            synth_method = obj.Synthesis_method;
            win = corpus_sound.Features.window;
            W = abs(corpus_sound.Features.STFT.S);
            H = obj.Activations;
            
            switch synth_method
                case 'ISTFT'
                    parameters = [];
                    parameters.synHop = win.Hop;
                    parameters.win = window(lower(win.Type), win.Length);

                    reconstruction = W*H;
                    padding = size(reconstruction, 1)*2 - win.Length - 2;
                    if padding >= 0
                        parameters.zeroPad = padding;
                    end

                    obj.Synthesis = istft(reconstruction, parameters);
                case 'Template Addition'
                    obj.Synthesis = templateAdditionResynth(corpus_sound.Signal, H, win);
            end
        end
        
        function plot_activations(obj, varargin)
            if(nargin > 1)
                maxDb = varargin{1};
            else
                maxDb = -45;
            end
            
            H = obj.Activations;
            
            HdB = 20*log10(H./max(max(H)));
            HdB = HdB - maxDb;
            HdB(HdB < 0) = 0;
            imagesc(HdB);
            cmap = colormap('gray');
            cmap(1,:) = 0*ones(1,3);
            colormap(flipud(cmap))
            colorbar
            axis xy; grid on;
            set(gca, 'Layer', 'top');
            ylabel('Template');
            xlabel('Time');
            grid on;
            set(gca,'FontSize',16);
        end
        
        function plot_cost(obj)
            plot(obj.Cost);
            xlabel('Iteration');
            ylabel('Cost');
            title('Cost vs. Iteration');
            grid on
        end
    end
end