// パラメータ設定用のインクルードファイル　各パラメータの実際の計算はここで行う

// 深度値をm単位に変換する係数　カメラのパラメータに依存しそうだが現状では分からない　今後の課題
_CameraDepthRate=5.0;
// パラメータを計算
float kFilmHeight = 0.024;
float s1 = _ManualFocusDistance;
//AF用深度取得　AFが有効な場合にはs1をAFで得られる距離で置き換え
if (_IsAF == 1){
    float depthCenter = _CameraDepthRate * LinearEyeDepth(SAMPLE_DEPTH_TEXTURE(_AltCameraDepthTexture,float2(0.5,0.5)));
    s1 = min(depthCenter, 10);
}
float f;
if (_IsCameraFOV == 1){
    f = 0.5 * kFilmHeight / tan(0.5 * _CameraFOV/57.29578049);
}else{
    f = _FocalLength/1000.0;
}
s1 = max(s1,f);
_Distance = s1;
_LensCoeff = f * f / (_FNumber * (s1 - f) * kFilmHeight * 2.0);
_RcpAspect = (float)_MainTex_TexelSize.x/_MainTex_TexelSize.y;
float _kernelSize = 2.0;
float radiusInPixels;
radiusInPixels = (_kernelSize * 4 + 6) * _MainTex_TexelSize.y;
_MaxCoC = min(0.05,radiusInPixels);
_RcpMaxCoC = 1.0/min(0.05,radiusInPixels);