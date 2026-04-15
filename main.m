function main()
    % =========================================================================
    %  Automated Color Calibration and Tobacco Leaf ROI Extraction Pipeline
    %  Main Execution Script
    % =========================================================================
    clc; close all; clear;
    
    %% -------- 0. Specify Image Path -------- %%
    imgPath = 'sample_image.jpg'; % Ensure the image exists in this directory
    
    if ~exist(imgPath, 'file')
        error('Image file not found: %s. Please check the samples folder or update imgPath.', imgPath);
    end
    fprintf('▶ Starting analysis for: %s\n', imgPath);
    
    %% -------- 1. Core Parameter Configuration -------- %%
    % A. Color Checker Localization & Cropping Parameters
    CONF.ChartThreshold = 0.33; 
    CONF.ChartParams.MinAreaRatio = 0.002;
    CONF.ChartParams.PatchROIPercent = 0.5; 
    
    % Horizontal and Vertical Margins
    CONF.ChartParams.Margin_Horizontal = 0.09; % Left/Right margin
    CONF.ChartParams.Margin_Vertical   = 0.02; % Top/Bottom margin
    
    % B. Background Segmentation Parameters
    CONF.Bg_RGB_Diff = 40;   
    CONF.Bg_B_Thresh = 100;  
    
    % C. Morphology & Stalk Cutting Parameters
    CONF.scanSafetyRatio = 0.25;      
    CONF.stalkThicknessThresh = 300;  
    CONF.EdgeErosionSize = 5;         
    
    % D. Defect Detection Parameters (Stems/Gaps/Shadows)
    CONF.DefectParams = [0.55, 0.60, 0.20, 1.6];
    
    % E. Standard X-Rite 24 Color Checker Data
    CONF.StandardRGB = [
        115,82,68; 194,150,130; 98,122,157; 87,108,67; 133,128,177; 103,189,170; 
        214,126,44; 80,91,166; 193,90,99; 94,60,108; 157,188,64; 224,163,46;   
        56,61,150; 70,148,73; 175,54,60; 231,199,31; 187,86,149; 8,133,161;    
        243,243,242; 200,200,200; 160,160,160; 122,122,121; 85,85,85; 52,52,52
    ];
    
    %% -------- 2. Preprocessing: Localization, Correction & Cropping -------- %%
    try
        [img_Raw, success, chartMask, ~, finalChart] = preprocessImage_V21_V27(imgPath, CONF);
        if ~success, error('Failed to locate the color checker. Try adjusting CONF.ChartThreshold.'); end
        
        %% -------- 3. Core Color Calibration (C1/C2/C3) -------- %%
        [img_C1, img_C2, img_C3, rawChartCrop] = applyAllCorrections(img_Raw, finalChart, CONF);
        
        %% -------- 4. Tobacco Leaf Mask Generation -------- %%
        [~, dbg_C1] = generateLeafMask(img_C1, chartMask, CONF);
        [~, dbg_C2] = generateLeafMask(img_C2, chartMask, CONF);
        [~, dbg_C3] = generateLeafMask(img_C3, chartMask, CONF);
        
        %% -------- 5. Results Visualization -------- %%
        showChartVisuals(rawChartCrop, CONF); 
        showDebugMontage(img_C1, img_C2, img_C3, dbg_C1, dbg_C2, dbg_C3); 
        
        fprintf('▶ Processing completed successfully! Two visualization windows have been generated.\n');
        
    catch ME
        fprintf('▶ Error occurred: %s\n', ME.message);
    end
end

%% ================== Core Function: Localization and Cropping ================== %%
function [img_Raw, success, chartMask, tform_final, finalChart] = preprocessImage_V21_V27(imgPath, CONF)
    success = false; [chartMask, tform_final, finalChart] = deal([]);
    img_Raw = imread(imgPath); [rawH, rawW, ~] = size(img_Raw); 
    hsvImg = rgb2hsv(img_Raw); vCh = hsvImg(:,:,3);
    
    bw = imfill(imclose(vCh < CONF.ChartThreshold, strel('disk', 3)), 'holes');
    stats = regionprops(bw, 'Area', 'ConvexHull', 'PixelIdxList');
    if isempty(stats), return; end
    
    minArea = CONF.ChartParams.MinAreaRatio * rawH * rawW;
    bestIdx = -1; maxRectScore = -1;
    for k = 1:length(stats)
        if stats(k).Area < minArea, continue; end
        [rectCorners, areaRect] = getMinBoundingRect(stats(k).ConvexHull);
        score = stats(k).Area / areaRect; 
        if score > maxRectScore
            maxRectScore = score; bestIdx = k; bestCorners = rectCorners;
        end
    end
    if bestIdx == -1 || maxRectScore < 0.60, return; end
    
    chartMask = false(rawH, rawW); chartMask(stats(bestIdx).PixelIdxList) = true;
    
    % 1. Force horizontal flattening to standard aspect ratio (600x400)
    geomCorners = sortCorners_Robust(bestCorners(1:4, :));
    stdW = 600; stdH = 400; dstPts = [1, 1; stdW, 1; stdW, stdH; 1, stdH];
    tform_final = fitgeotrans(geomCorners, dstPts, 'projective');
    rectFull = imwarp(img_Raw, tform_final, 'OutputView', imref2d([stdH, stdW]));
    
    % 2. Static margin cropping
    mL = CONF.ChartParams.Margin_Horizontal;
    mR = CONF.ChartParams.Margin_Horizontal;
    mT = CONF.ChartParams.Margin_Vertical;
    mB = CONF.ChartParams.Margin_Vertical;
    
    croppedChart = imcrop(rectFull, [stdW*mL+1, stdH*mT+1, stdW*(1-mL-mR)-1, stdH*(1-mT-mB)-1]);
    
    % 3. Strict 3:2 aspect ratio scaling to ensure perfect square patches
    croppedChart = imresize(croppedChart, [400, 600]);
    
    % 4. Rotation correction (preventing mirror flips)
    finalChart = correctChartOrientation(croppedChart);
    success = true;
end

%% ================== Rotation Correction (Anchor Bottom-Left) ================== %%
function finalChart = correctChartOrientation(chartImg)
    hsv_c = rgb2hsv(chartImg); S = hsv_c(:,:,2); [cH, ~] = size(S);
    if mean(S(1:floor(cH/4), :), 'all') < mean(S(floor(3*cH/4):end, :), 'all')
        chartImg = imrotate(chartImg, 180);
    end
    hsv_v = rgb2hsv(chartImg); V = hsv_v(:,:,3); [cH_new, cW_new] = size(V);
    mBL = mean(V(floor(3*cH_new/4):end, 1:floor(cW_new/6)), 'all');
    mBR = mean(V(floor(3*cH_new/4):end, floor(5*cW_new/6):end), 'all');
    if mBL < mBR, chartImg = fliplr(chartImg); end
    finalChart = chartImg;
end

%% ================== Core Function: Calibration and ROI Generation ================== %%
function [img_C1, img_C2, img_C3, rawChartCrop] = applyAllCorrections(img_Raw, finalChart, CONF)
    [cH, cW, ~] = size(finalChart); bH = cH/4; bW = cW/6;
    roiH = floor(bH * CONF.ChartParams.PatchROIPercent / 2); 
    roiW = floor(bW * CONF.ChartParams.PatchROIPercent / 2);
    
    actualRGB = zeros(24, 3); idx = 1;
    for i = 1:4 
        for j = 1:6
            yc = round((i-0.5)*bH); xc = round((j-0.5)*bW);
            patch = finalChart(max(1,yc-roiH):min(cH,yc+roiH), max(1,xc-roiW):min(cW,xc+roiW), :);
            actualRGB(idx, :) = mean(reshape(patch, [], 3), 1); 
            idx = idx + 1;
        end
    end
    
    actual_lin = max(1e-6, srgb2lin(actualRGB)); std_lin = srgb2lin(CONF.StandardRGB);
    img_lin = max(1e-6, srgb2lin(img_Raw)); [H, W, ~] = size(img_lin); img_vec = reshape(img_lin, [], 3);
    
    % C1: White Balance Calibration
    gain = std_lin(22, :) ./ actual_lin(22, :);
    img_C1 = lin2srgb(reshape(bsxfun(@times, img_vec, gain), H, W, 3));
    
    % C2: Linear Matrix Calibration (CCM)
    M_C2 = actual_lin \ std_lin;
    img_C2 = lin2srgb(reshape(img_vec * M_C2, H, W, 3));
    
    % C3: 13-dimensional Root Polynomial Calibration
    R = actual_lin(:,1); G = actual_lin(:,2); B = actual_lin(:,3);
    P_C3 = [R, G, B, sqrt(R.*G), sqrt(R.*B), sqrt(G.*B), (R.*G.*B).^(1/3), (R.^2 .* G).^(1/3), (R.*G.^2).^(1/3), (R.^2 .* B).^(1/3), (R.*B.^2).^(1/3), (G.^2 .* B).^(1/3), (G.*B.^2).^(1/3)];
    opt_lam = findOptimalLambda_LOOCV(P_C3, std_lin); 
    M_C3 = (P_C3' * P_C3 + opt_lam * eye(size(P_C3, 2))) \ (P_C3' * std_lin);
    
    iR = img_vec(:,1); iG = img_vec(:,2); iB = img_vec(:,3);
    
    feat_C3 = [iR, iG, iB, sqrt(iR.*iG), sqrt(iR.*iB), sqrt(iG.*iB), (iR.*iG.*iB).^(1/3), (iR.^2 .* iG).^(1/3), (iR.*iG.^2).^(1/3), (iR.^2 .* iB).^(1/3), (iR.*iB.^2).^(1/3), (iG.^2 .* iB).^(1/3), (iG.*iB.^2).^(1/3)];
    img_C3 = lin2srgb(reshape(feat_C3 * M_C3, H, W, 3));
    
    rawChartCrop = finalChart;
end

%% ================== Helper Functions & Visualization ================== %%
function bestLambda = findOptimalLambda_LOOCV(P_root, stdRGB_lin)
    lambdas = logspace(log10(0.001), log10(10), 40); nPatches = size(P_root, 1); meanErrors = zeros(size(lambdas));
    for i = 1:length(lambdas)
        currLam = lambdas(i); totalError = 0;
        for k = 1:nPatches
            train_P = P_root; train_P(k, :) = []; train_T = stdRGB_lin; train_T(k, :) = [];
            M = (train_P' * train_P + currLam * eye(size(train_P, 2)));
            C_k = M \ (train_P' * train_T); pred_lin = max(0, P_root(k, :) * C_k);
            totalError = totalError + norm(pred_lin - stdRGB_lin(k, :));
        end
        meanErrors(i) = totalError / nPatches;
    end
    [~, minIdx] = min(meanErrors); bestLambda = lambdas(minIdx); 
    if bestLambda < 0.01, bestLambda = 0.01; end
end

function [finalMask, debugInfo] = generateLeafMask(imgRGB, chartMask, CONF)
    [H, W, ~] = size(imgRGB); imgD = double(imgRGB); B_ch = imgD(:,:,3);
    RGB_Range = max(imgD, [], 3) - min(imgD, [], 3);
    mask_raw = ~((B_ch > CONF.Bg_B_Thresh) & (RGB_Range < CONF.Bg_RGB_Diff));
    mask_clean = imfill(imclose(mask_raw, strel('rectangle', [5, 5])), 'holes');
    mask_clean(chartMask) = 0; 
    stats = regionprops(mask_clean, 'Area', 'PixelIdxList', 'BoundingBox');
    if isempty(stats), finalMask=false(H,W); debugInfo.Initial=false(H,W); debugInfo.StalkCut=false(H,W); debugInfo.Defects=false(H,W); return; end
    [~, maxIdx] = max([stats.Area]); mask_MainBlob = false(H, W); mask_MainBlob(stats(maxIdx).PixelIdxList) = true;
    mask_LeafShape = mask_MainBlob & mask_raw; debugInfo.Initial = mask_LeafShape; mask_BeforeCut = mask_LeafShape;
    bb = stats(maxIdx).BoundingBox; minCol = max(1, floor(bb(1))); leafW = bb(3); maxScanCol = min(W, floor(minCol + leafW * CONF.scanSafetyRatio));
    for c = minCol : maxScanCol
        if sum(mask_LeafShape(:, c)) < CONF.stalkThicknessThresh, mask_LeafShape(:, c) = 0; else, isSolid=true; for check=1:5, if (c+check)>maxScanCol || sum(mask_LeafShape(:, c+check))<CONF.stalkThicknessThresh, isSolid=false; break; end, end; if isSolid, break; else, mask_LeafShape(:, c)=0; end, end
    end
    mask_LeafShape(:, minCol:min(W, floor(bb(1))+8)) = 0; mask_LeafShape = bwareaopen(mask_LeafShape, 1000);
    debugInfo.StalkCut = mask_BeforeCut & ~mask_LeafShape;
    hsv = rgb2hsv(imgRGB); vCh = hsv(:,:,3); sCh = hsv(:,:,2); localStd = stdfilt(vCh, true(5));
    validS = localStd(mask_LeafShape); if ~isempty(validS), stdTh = graythresh(validS)*CONF.DefectParams(4); mask_W = (localStd > stdTh) & mask_LeafShape; else, mask_W = false(H,W); end
    mask_S = (vCh < CONF.DefectParams(1)) & (sCh < CONF.DefectParams(2)) & mask_LeafShape;
    mask_Sh = (vCh < CONF.DefectParams(3)) & mask_LeafShape;
    debugInfo.Defects = mask_W | mask_S | mask_Sh;
    mask_T = imerode(mask_LeafShape, strel('disk', CONF.EdgeErosionSize));
    finalMask = bwareaopen(mask_T & ~debugInfo.Defects, 200);
end

function sorted = sortCorners_Robust(pts)
    cx = mean(pts(:,1)); cy = mean(pts(:,2)); angles = atan2(pts(:,2)-cy, pts(:,1)-cx);
    [~, order] = sort(angles); pts = pts(order, :); dists = sum(pts, 2); [~, tlIdx] = min(dists);
    sorted = circshift(pts, -(tlIdx-1));
    if norm(sorted(1,:) - sorted(2,:)) < norm(sorted(2,:) - sorted(3,:)), sorted = circshift(sorted, -1); end
end

function [rect, area] = getMinBoundingRect(hull)
    n = size(hull, 1) - 1; area = Inf; rect = [];
    for i = 1:n
        p1 = hull(i,:); p2 = hull(i+1,:); ang = atan2(p2(2)-p1(2), p2(1)-p1(1));
        R = [cos(-ang) -sin(-ang); sin(-ang) cos(-ang)]; rotH = (R * hull')';
        mx = min(rotH(:,1)); Mx = max(rotH(:,1)); my = min(rotH(:,2)); My = max(rotH(:,2));
        if (Mx-mx)*(My-my) < area, area = (Mx-mx)*(My-my); res = [mx my; Mx my; Mx My; mx My]; rect = (R' * res')'; end
    end
end

function lin = srgb2lin(s), s=double(s)/255; lin=zeros(size(s)); idx=s<=0.04045; lin(idx)=s(idx)/12.92; lin(~idx)=((s(~idx)+0.055)/1.055).^2.4; end
function s = lin2srgb(l), l=max(0,min(1,l)); s=zeros(size(l)); idx=l<=0.0031308; s(idx)=l(idx)*12.92; s(~idx)=1.055*(l(~idx).^(1/2.4))-0.055; s=uint8(round(s*255)); end

function showChartVisuals(chartImg, CONF)
    [H, W, ~] = size(chartImg); bH = H/4; bW = W/6;
    roiSide = floor(min(bH, bW) * CONF.ChartParams.PatchROIPercent / 2); 
    vis = chartImg;
    for i = 1:4, for j = 1:6
        yc = round((i-0.5)*bH); xc = round((j-0.5)*bW);
        vis = insertShape(vis, 'Rectangle', [xc-roiSide, yc-roiSide, 2*roiSide, 2*roiSide], 'Color', 'cyan', 'LineWidth', 2);
    end, end
    figure('Name', 'Color Checker Verification', 'NumberTitle', 'off'); imshow(vis);
    title('Universal Orientation Verification');
end

function showDebugMontage(c1, c2, c3, dbgC1, dbgC2, dbgC3)
    targetH = 400; 
    function rowImg = processOneRow(imgRGB, dbgInfo, rowLabel)
        imgSmall = imresize(imgRGB, [targetH, NaN]); [h, w, ~] = size(imgSmall);
        col1 = insertText(imgSmall, [10, 10], rowLabel, 'FontSize', 24, 'BoxColor', 'black', 'TextColor', 'white');
        col2 = labeloverlay(imgSmall, imresize(dbgInfo.Initial, [h, w], 'nearest'), 'Colormap', [0 1 0], 'Transparency', 0.6);
        col2 = insertText(col2, [10, 10], '1. BG Removal', 'FontSize', 18, 'BoxOpacity', 0.6);
        mS = imresize(dbgInfo.StalkCut, [h, w], 'nearest');
        if any(mS(:)), col3 = labeloverlay(imgSmall, mS, 'Colormap', [1 0 0], 'Transparency', 0.4); else, col3 = insertText(imgSmall, [w/2-50, h/2], 'No Stalk', 'FontSize', 24, 'BoxColor', 'white'); end
        col3 = insertText(col3, [10, 10], '2. Stalk Cut', 'FontSize', 18, 'BoxOpacity', 0.6);
        col4 = labeloverlay(imgSmall, imresize(dbgInfo.Defects, [h, w], 'nearest'), 'Colormap', [1 0 1], 'Transparency', 0.4);
        col4 = insertText(col4, [10, 10], '3. Defects', 'FontSize', 18, 'BoxOpacity', 0.6);
        mF = imresize(dbgInfo.Initial, [h, w], 'nearest') & ~mS & ~imresize(dbgInfo.Defects, [h, w], 'nearest'); 
        col5 = imgSmall; repM = repmat(mF, [1,1,3]); col5(~repM) = 0;
        col5 = insertText(col5, [10, 10], '4. Final Mask', 'FontSize', 18, 'BoxOpacity', 0.6);
        rowImg = cat(2, col1, col2, col3, col4, col5);
    end
    r2 = processOneRow(c1, dbgC1, 'Method: C1'); r3 = processOneRow(c2, dbgC2, 'Method: C2'); r4 = processOneRow(c3, dbgC3, 'Method: C3');
    mW = max([size(r2,2), size(r3,2), size(r4,2)]); padR = @(im) padarray(im, [0, mW - size(im,2)], 0, 'post');
    figure('Name', 'Mask Generation Debug', 'NumberTitle', 'off', 'Position', [100 100 1200 600]);
    imshow(cat(1, padR(r2), padR(r3), padR(r4))); title('Mask Generation Pipeline');
end
