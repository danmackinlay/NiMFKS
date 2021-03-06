%Used for the plot drawing function
function drawClickCallBack(src,callbackdata, action)
matlabVer = version;
handles = guidata(src);
ah = handles.axes2;
if(strcmp(matlabVer, '9.0.0.341360 (R2016a)'))
    xAxisProps = get(ah, 'XAxis');
    xLimits = get(xAxisProps, 'Limits')
else
    xAxisProps = get(ah, 'Xlim');
    xLimits = xAxisProps
end

acts = handles.SynthesisObject.Activations;

yMax = size(acts, 1);
xMax = size(acts, 2);

xUnit = xLimits/size(acts, 2);

sliderHandle = handles.sld_actstrength;

paintBrush = handles.grp_paintbrush.SelectedObject.String;
paintBrushSize = 0;

if(strcmp(paintBrush, 'Large Brush'))
    paintBrushSize = 1;
else(strcmp(paintBrush, 'Small Brush'))
    paintBrushSize = 0;
end

if(strcmp(action, 'Draw'))
    src.Pointer = 'cross';
    fillValue = get(sliderHandle, 'Value')
elseif(strcmp(action, 'Erase'))
	src.Pointer = 'circle';
    fillValue = 0;
end

cp = ah.CurrentPoint;
cx = cp(1,1)/xUnit(2)
cy = cp(1,2)

drawXMax = (ceil(cx) + paintBrushSize);
drawYMax = (ceil(cy) + paintBrushSize);
drawXMin = (ceil(cx) - paintBrushSize);
drawYMin = (ceil(cy) - paintBrushSize);

if(drawXMax >= xMax)
	drawXMax = xMax;
end
    
if(drawYMax >= yMax)
	drawYMax = yMax;
end

if(drawXMin <=0)
    drawXMin = 1;
end

if(drawYMin <=0)
    drawYMin = 1;
end

acts(drawYMin:drawYMax, drawXMin:drawXMax) = fillValue;
handles.SynthesisObject.Activations = acts;
size(acts, 1)
guidata(src, handles);

src.WindowButtonMotionFcn = @dragCallBack;
src.WindowButtonUpFcn = @releaseCallBack;

    function dragCallBack(src, callbackdata)
        cp = ah.CurrentPoint;
        cx = cp(1,1)/xUnit(2);
        cy = cp(1,2);
        
        drawXMax = (ceil(cx) + paintBrushSize);
        drawYMax = (ceil(cy) + paintBrushSize);
        drawXMin = (ceil(cx) - paintBrushSize);
        drawYMin = (ceil(cy) - paintBrushSize);
        
        if(drawXMax >= xMax)
            drawXMax = xMax;
        end
        
        if(drawYMax >= yMax)
            drawYMax = yMax;
        end
        
        if(drawXMin <=0)
            drawXMin = 1;
        end
        
        if(drawYMin <=0)
            drawYMin = 1;
        end
        
        %         fprintf('X: %u Y: %u', ceil(cy), ceil(cx))
        acts(drawYMin:drawYMax, drawXMin:drawXMax) = fillValue;
        handles.SynthesisObject.Activations = acts;
        guidata(src, handles);
    end

    function releaseCallBack(src, callbackdata)
        controller('switchPlot', handles);
        src.Pointer = 'arrow';
        src.WindowButtonMotionFcn = '';
        src.WindowButtonUpFcn = '';
    end
end