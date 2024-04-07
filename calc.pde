boolean isOver(float x1, float y1, float w1, float h1, float x2, float y2, float w2, float h2) {  //2つの矩形の重なりを判定する関数
  return x1 < x2 + w2 && x2 < x1 + w1 && y1 < y2 + h2 && y2 < y1 + h1;
}

int range(int n, int min, int max) {  //nで指定された値を指定された範囲に収める関数
  return min(max(n, min), max);
}
float range(float n, float min, float max) {
  return min(max(n, min), max);
}

float[] hexToRgb(String hex) {  //HEX(#XXXXXX)をHSVに変換する関数
  float[] rgb = new float[3];  //RGBを格納
  for (int i = 0; i < 3; ++i) {  //文字列を2文字ずつに区切って10進数に変換
    rgb[i] = unhex(hex.substring(i * 2, i * 2 + 2));
  }
  return rgb;  //RGBを返す
}

String rgbToHex(float r, float g, float b) {  //RGBをHEXに変換する関数
  return rgbToHex(new float[]{r, g, b});
}
String rgbToHex(float[] rgb) {
  String hex = "";  //HEXの文字列
  for (int i = 0; i < rgb.length; ++i) {  //RGBをそれぞれ16進数の文字列に変換し、2文字に0埋めして文字列に追加
    hex += String.format("%2s", Integer.toHexString(round(rgb[i]))).replace(" ", "0").toUpperCase();
  }
  return hex;  //HEXを返す
}

float[] hsvToRgb(float[] hsv) {  //HSVをRGBに変換する関数 参考: https://www.peko-step.com/tool/hsvrgb.html
  return hsvToRgb(hsv[0], hsv[1], hsv[2]);
}
float[] hsvToRgb(float h, float s, float v) {
  v *= 255.0 / 100.0;  //輝度を正規化
  float min = v - s * v / 100;  //RGBの最小値
  float r = 0, g = 0, b = 0;
  switch (int(h / 60) % 6) {  //色相による分岐
    case 0:  //0 <= H < 60
      r = v;
      g = h * (v - min) / 60 + min;
      b = min;
      break;
    case 1:  //60 <= H < 120
      r = (120 - h) * (v - min) / 60 + min;
      g = v;
      b = min;
      break;
    case 2:  //120 <= H < 180
      r = min;
      g = v;
      b = (h - 120) * (v - min) / 60 + min;
      break;
    case 3:  //180 <= H < 240
      r = min;
      g = (240 - h) * (v - min) / 60 + min;
      b = v;
      break;
    case 4:  //240 <= H < 300
      r = (h - 240) * (v - min) / 60 + min;
      g = min;
      b = v;
      break;
    case 5:  //300 <= H < 360
      r = v;
      g = min;
      b = (360 - h) * (v - min) / 60 + min;
      break;
  }
  return new float[]{range(r, 0, 255), range(g, 0, 255), range(b, 0, 255)};  //RGBを返す
}

float[] rgbToHsv(float[] rgb) {  //RGBをHSVに変換する関数 参考: https://www.peko-step.com/tool/hsvrgb.html
  return rgbToHsv(rgb[0], rgb[1], rgb[2]);
}
float[] rgbToHsv(float r, float g, float b) {
  float max = max(r, g, b);  //RGBの最大値
  float min = min(r, g, b);  //RGBの最小値
  float h = 0, s = 0, v = 0;
  if (max == min)  //色相を計算
    h = 0;
  else if (max == r) 
    h = (g - b) * 60 / (max - min);
  else if (max == g)
    h = (b - r) * 60 / (max - min) + 120;
  else if (max == b)
    h = (r - g) * 60 / (max - min) + 240;
  h = (h + 360) % 360;  //色相を正規化
  s = (max - min) * 100 / max;  //彩度を計算
  v = max * 100 / 255;  //輝度を計算
  return new float[]{range(h, 0, 360), range(s, 0, 100), range(v, 0, 200)};  //HSVを返す
}

float[] hexToHsv(String hex) {  //HEXをHSVに変換する関数
  float[] rgb = hexToRgb(hex);  //HEXをRGBに変換
  return rgbToHsv(rgb[0], rgb[1], rgb[2]);  //RGBをHSVに変換して返す
}

String hsvToHex(float[] hsv) {  //HSVをHEXに変換する関数
  return hsvToHex(hsv[0], hsv[1], hsv[2]);
}
String hsvToHex(float h, float s, float v) {
  float[] rgb = hsvToRgb(h, s, v);  //HSVをRGBに変換
  return rgbToHex(rgb);  //RGBをHEXに変換して返す
}

void fill(float[] rgb) {  //fillが引数に配列もとるようにオーバーロード
  fill(rgb[0], rgb[1], rgb[2]);
}
void stroke(float[] rgb) {  //strokeが引数に配列もとるようにオーバーロード
  stroke(rgb[0], rgb[1], rgb[2]);
}

void selectFile(String prompt, FileObserver observer) {  //selectInputに関する操作をまとめて行う関数
  if (handlingFileObsever == null) {
    selectInput(prompt, "fileSelected");  //Processing組み込みのselectInput関数を第2引数"sileSelected"固定で呼び出し
    handlingFileObsever = observer;  //現在のファイル選択を管理するインスタンスを参照
  }
}

float diffDegrees(float degrees0, float degrees1) {  //角度の差を計算する関数
  return min(abs(degrees0 - degrees1), 360 - abs(degrees0 - degrees1));  //角度の差を計算して返す
}
