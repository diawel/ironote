class ColorPanel extends Component {  //色の操作パネル
  EditedPalette palette;  //編集中のパレット
  float lx;  //色リストと接続する線のx座標

  ColorPanel(int x, int y, int w, int h, EditedPalette editedPalette) {  //editedPalette: 編集中のパレット
    cx = x;  //各変数を設定
    cy = y;
    cw = w;
    ch = h;
    palette = editedPalette;
    lx = cx + cw * (palette.editedColor + 0.5) / palette.colors.length;
  }

  void draw() {
    float[] rgb = hsvToRgb(palette.editedColor());  //編集中の色をRGBに変換
    lx += (cx + cw * (palette.editedColor + 0.5) / palette.colors.length - lx) / 8;  //色リストと接続する線の位置を更新
    noFill();
    stroke(rgb);
    strokeWeight(2);
    rect(cx, cy, cw, ch, 12);
    line(lx, cy + ch, lx, cy + ch + 40);
  }
}

class ColorWheel extends Component {  //カラーホイール
  int wr;  //半径
  EditedPalette palette;  //編集中のパレット

  ColorWheel(int x, int y, int r, EditedPalette editedPalette) {  //editedPalette: 編集中のパレット
    cx = x;  //各変数を設定
    cy = y;
    cw = 2 * r;  //引数で設定された半径からコンポーネントのサイズを計算
    ch = 2 * r;
    wr = r;
    palette = editedPalette;
  }

  void draw() {
    float[] hsv = palette.editedColor();  //編集中の色を取得
    noStroke();
    for (float h = 0; h < 360; h += 360 / 2 / wr / PI) {  //カラーホイール内の各ピクセルの色を計算し描画
      for (float r = 0; r < wr; ++r) {
        float[] rgb = hsvToRgb(h, r * 100 / wr, hsv[2]);
        fill(rgb);
        rect(cx + wr + r * cos(radians(h)), cy + wr + r * sin(radians(h)), 1, 1);
      }
    }
    noFill();  //輪郭線を描画
    stroke(163);
    strokeWeight(1);
    circle(cx + wr, cy + wr, 2 * wr);
    fill(hsvToRgb(hsv));  //色変更用のつまみを描画
    strokeWeight(4);
    circle(cx + wr + wr * hsv[1] * cos(radians(hsv[0])) / 100, cy + wr + wr * hsv[1] * sin(radians(hsv[0])) / 100, 16);
    stroke(255);
    strokeWeight(2);
    circle(cx + wr + wr * hsv[1] * cos(radians(hsv[0])) / 100, cy + wr + wr * hsv[1] * sin(radians(hsv[0])) / 100, 16);
  }

  void mouseDragged() {  //マウス押下時、ドラッグ時共通でmouseActionを呼び出し
    mouseAction();
  }
  
  void mousePressed() {
    mouseAction();
  }

  void mouseAction() {  //マウス押下時、ドラック時共通でマウスの位置につまみを移動
    float[] hsv = palette.editedColor();
    hsv[0] = (degrees(atan2(mouseX - cx - cw / 2, cy + ch / 2 - mouseY)) + 270) % 360;  //マウスの座標から色相を計算
    hsv[1] = range(round(dist(mouseX, mouseY, cx + cw / 2, cy + ch / 2) * 100 / wr), 0, 100);  //マウスの座標から彩度を計算
  }
}

class BrightnessBar extends Component {  //輝度バー
  EditedPalette palette;  //編集中のパレット

  BrightnessBar(int x, int y, int w, int h, EditedPalette editedPalette) {  //editedPalette: 編集中のパレット
    cx = x;  //各変数を設定
    cy = y;
    cw = w;
    ch = h;
    palette = editedPalette;
  }

  void draw() {
    float[] hsv = palette.editedColor();  //編集中の色を取得
    noStroke();
    for (int y = 0; y < ch; ++y) {  //輝度バーを一行ずつ描画
      fill(255 - y * 255 / ch);
      rect(cx, cy + y, cw, 1);
    }
    noFill();  //輪郭線を描画
    stroke(163);
    strokeWeight(1);
    rect(cx, cy, cw, ch);
    fill(hsvToRgb(0, 0, hsv[2]));  //輝度変更用のつまみを描画
    strokeWeight(4);
    circle(cx + cw / 2, cy + ch * (100 - hsv[2]) / 100, 16);
    stroke(255);
    strokeWeight(2);
    circle(cx + cw / 2, cy + ch * (100 - hsv[2]) / 100, 16);
  }

  void mouseDragged() { //マウス押下時、ドラッグ時共通でmouseActionを呼び出し
    mouseAction();
  }
  
  void mousePressed() {
    mouseAction();
  }

  void mouseAction() {  //マウス押下時、ドラック時共通でマウスの位置につまみを移動
    float[] hsv = palette.editedColor();
    hsv[2] = range(100 - (mouseY - cy) * 100 / ch, 0, 100);  //マウスの座標から輝度を計算
  }
}

class Rgb extends Component implements TextInputObserver {  //RGBのテキスト入力欄
  TextInput[] textInputs = new TextInput[3];  //3つのテキスト入力欄
  EditedPalette palette;  //編集中のパレット

  Rgb(int x, int y, EditedPalette editedPalette) {
    cx = x;  //各変数を設定
    cy = y;
    cw = 162;
    ch = 22;
    palette = editedPalette;
    textInputs[2] = new TextInput(cx + 130, cy, 32, 22, this, null);  //3つのテキスト入力欄を生成
    textInputs[1] = new TextInput(cx + 90, cy, 32, 22, this, textInputs[2]);  //次の入力欄として1つ後ろの入力欄を設定
    textInputs[0] = new TextInput(cx + 50, cy, 32, 22, this, textInputs[1]);
    for (int i = 0; i < textInputs.length; ++i)  //各テキスト入力欄をコンポーネントのリストに追加
      components.add(textInputs[i]);
  }

  void draw() {
    fill(18);  //入力欄のタイトルを描画
    textFont(NotoSans_m);
    textSize(18);
    textAlign(LEFT, TOP);
    text("RGB", cx, cy);
    float[] rgb = hsvToRgb(palette.editedColor());  //編集中の色をRGBに変換
    for (int i = 0; i < textInputs.length; ++i)  //各テキスト入力欄が選択されていなければ、パレットのデータに基づいた値を設定
      if (!textInputs[i].isSelected)
        textInputs[i].value = Integer.valueOf(round(rgb[i])).toString();
    drawComponents();
  }
  
  void onblur(TextInput instance) {  //テキスト入力欄の選択が解除されたとき
    if (instance.value.matches("\\d*(\\.\\d+)?")) {  //入力されたものが数字なら
      for (int i = 0; i < textInputs.length; ++i) {  //入力されたデータをもとにパレットのデータを更新
        if (textInputs[i] == instance) {
          float value = round(Float.valueOf(instance.value));
          float[] rgb = hsvToRgb(palette.editedColor());
          rgb[i] = range(value, 0, 255);  //入力された値を正規化
          palette.updateEditedColor(rgbToHsv(rgb));  //パレットのデータを更新
        }
      }
    }
  }
}

class Hsv extends Component implements TextInputObserver {  //HSVのテキスト入力欄
  TextInput[] textInputs = new TextInput[3];  //3つのテキスト入力欄
  EditedPalette palette;  //編集中のパレット

  Hsv(int x, int y, EditedPalette editedPalette) {  //editedPalette: 編集中のパレット
    cx = x;  //各変数を設定
    cy = y;
    cw = 162;
    ch = 22;
    palette = editedPalette;
    textInputs[2] = new TextInput(cx + 130, cy, 32, 22, this, null);  //3つのテキスト入力欄を生成
    textInputs[1] = new TextInput(cx + 90, cy, 32, 22, this, textInputs[2]);  //次の入力欄として1つ後ろの入力欄を設定
    textInputs[0] = new TextInput(cx + 50, cy, 32, 22, this, textInputs[1]);
    for (int i = 0; i < textInputs.length; ++i)  //各テキスト入力欄をコンポーネントのリストに追加
      components.add(textInputs[i]);
  }

  void draw() {
    fill(18);  //入力欄のタイトルを描画
    textFont(NotoSans_m);
    textSize(18);
    textAlign(LEFT, TOP);
    text("HSV", cx, cy);
    float[] hsv = palette.editedColor();  //編集中の色を取得
    for (int i = 0; i < textInputs.length; ++i)  //各テキスト入力欄が選択されていなければ、パレットのデータに基づいた値を設定
      if (!textInputs[i].isSelected)
        textInputs[i].value = Integer.valueOf(round(hsv[i])).toString();
    drawComponents();
  }

  void onblur(TextInput instance) {  //テキスト入力欄の選択が解除されたとき
    if (instance.value.matches("\\d*(\\.\\d+)?")) {  //入力されたものが数字なら
      for (int i = 0; i < textInputs.length; ++i) {  //入力されたデータをもとにパレットのデータを更新
        if (textInputs[i] == instance) {
          float value = round(Float.valueOf(instance.value));
          if (i == 0)  //入力された値を正規化
            value = value % 360;
          else
            value = range(value, 0, 100);
          palette.editedColor()[i] = value;  //パレットのデータを更新
        }
      }
    }
  }
}

class Hex extends Component implements TextInputObserver {  //HEXのテキスト入力欄
  TextInput textInput;  //テキスト入力欄
  EditedPalette palette;  //編集中のパレット

  Hex(int x, int y, EditedPalette editedPalette) {  //editedPalette: 編集中のパレット
    cx = x;  //各変数を設定
    cy = y;
    cw = 162;
    ch = 22;
    palette = editedPalette;
    textInput = new TextInput(cx + 50, cy, 112, 22, this, null);  //テキスト入力欄を生成
    components.add(textInput);  //テキスト入力欄をコンポーネントのリストに追加
  }

  void draw() {
    fill(18);  //入力欄のタイトルを描画
    textFont(NotoSans_m);
    textSize(18);
    textAlign(LEFT, TOP);
    text("HEX", cx, cy);
    if (!textInput.isSelected)  //各テキスト入力欄が選択されていなければ、パレットのデータに基づいた値を設定
      textInput.value = "#" + hsvToHex(palette.editedColor());
    drawComponents();
  }

  void onblur(TextInput instance) {
    Matcher matcher = Pattern.compile("^#?((\\d|[a-f]|[A-F]){3}|(\\d|[a-f]|[A-F]){6})$").matcher(instance.value);  //正規表現でHEXを抽出
    if (matcher.find()){
      String hex = matcher.group(1);
      if (hex.length() == 3) {  //3文字表記のときには6文字表記に整形
        String formatedHex = "";
        for (int i = 0; i < 3; ++i) {
          String letter = hex.substring(i, i + 1);
          formatedHex += letter + letter;
        }
        hex = formatedHex;
      }
      palette.updateEditedColor(hexToHsv(hex));  //HEXをHSVに変換してパレットのデータを更新
    }
  }
}
