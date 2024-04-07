class ImgPanel extends Component implements FileObserver {  //画像操作パネル
  EditedPalette palette;  //編集中のパレット
  PImage image;  //入力された画像
  Loading loading;  //読み込み画面
  ColorPicker[] colorPickers;  //カラーピッカー

  ImgPanel(int x, int y, int w, int h, EditedPalette editedPalette) {  //editedPalette: 編集中のパレット
    cx = x;  //各変数を設定
    cy = y;
    cw = w;
    ch = h;
    palette = editedPalette;
    colorPickers = new ColorPicker[palette.colors.length];  //カラーピッカーをパレットの色の数だけ生成
    for (int i = 0; i < colorPickers.length; ++i) {
      colorPickers[i] = new ColorPicker(i, this);
      components.add(colorPickers[i]);  //カラーピッカーをコンポーネントのリストに追加
    }
  }

  void draw() {
    PImage capturedScreen = createImage(width, height, RGB);  //画像のはみ出し分を覆うために現在の画面をキャプチャ
    loadPixels();
    capturedScreen.pixels = pixels;
    for (int y = cy; y < cy + ch; ++y)  //キャプチャした画像からこのコンポーネントの部分を削除
      for (int x = cx; x < cx + cw; ++x)
        capturedScreen.pixels[y * width + x] = color(0, 0);
    if (image == null) {  //画像が未選択のときはヒントを表示
      fill(18);
      textAlign(CENTER, CENTER);
      textSize(18);
      text("クリックして画像を選択", cx + cw / 2, cy + ch / 2);
    } else {  //画像が選択済みのときは画像を描画
      image(image, cx + cw / 2 - image.width / 2, cy + ch / 2 - image.height / 2);
    }
    image(capturedScreen, 0, 0);  //画像がはみ出した部分を削除
    noFill();
    stroke(163);
    strokeWeight(1);
    rect(cx, cy, cw, ch, 12);
    drawComponents();
  }

  void mouseClicked() {
    selectFile("画像を選択", this);  //画像選択ウィンドウを開く
  }

  void fileSelected(File selection) {
    if (selection != null) {
      String absolutePath = selection.getAbsolutePath();
      try {
        if (Files.probeContentType(Paths.get(absolutePath)).matches("image/.+")) {  //選択されたファイルが画像のときのみ読み込み
          image = loadImage(absolutePath);
          if (image != null) {  //読み込みに成功したとき
            loading = new Loading();  //読み込み画面を生成
            page.components.add(loading);
            float ratio = min(float(cw) / image.width, float(ch) / image.height);  //画像を画像操作パネルの大きさに合わせてリサイズ
            image.resize(round(image.width * ratio), round(image.height * ratio));
            image.loadPixels();
            ArrayList<int[]> rgbList = new ArrayList<int[]>();  //画像に含まれる色のリスト
            int skip = 64;  //最初は64ピクセルに1つの割合で色を取得
            while (rgbList.size() < 100 && skip >= 1) {  //取得した色が少なすぎる場合は取得する割合を増やして再取得
              rgbList.clear();
              for (int i = 0; i < image.pixels.length; i += skip)
                if (alpha(image.pixels[i]) == 255)  //透過ピクセルは無視する
                  rgbList.add(new int[]{round(red(image.pixels[i])), round(green(image.pixels[i])), round(blue(image.pixels[i]))});
              skip /= 2;
            }
            if (rgbList.size() >= 100) {  //k-means 参考: https://qiita.com/navitime_tech/items/bb1bd01537bc2713444a
              int clusters = 5;  //検出する色(分類するクラスタ)の数
              int loop = 40000;  //最大の反復回数
              int[] assigns = new int[rgbList.size()];  //分類されたクラスタを保持
              for (int i = 0; i < rgbList.size(); ++i)
                assigns[i] = int(random(clusters));  //検出された各色にランダムでクラスタを割り当て
              float[][] aves = new float[clusters][3];  //各クラスタの平均色を保持
              for (int n = 0; n < loop; ++n) {
                int[] lastAssigns = assigns.clone();  //直前のクラスタの割り当てを保持
                aves = new float[clusters][3];  //各クラスタの中心の座標を計算
                float[][] sums = new float[clusters][3];  //各クラスタのRGBの平均をそれぞれ保持
                int[] items = new int[clusters];  //各クラスタに属する色の数を保持
                for (int i = 0; i < assigns.length; ++i) {  //各クラスタのRGBの総和をとる
                  for (int j = 0; j < 3; ++j)
                    sums[assigns[i]][j] += rgbList.get(i)[j];
                  items[assigns[i]]++;  //各クラスタの色の数を数える
                }
                for (int c = 0; c < clusters; ++c)  //各クラスタの色の平均をとる
                  for (int i = 0; i < 3; ++i)
                    aves[c][i] = sums[c][i] / items[c];
                for (int i = 0; i < assigns.length; ++i) {  //最も近いクラスタに各色を再割り当て
                  float minDist = pow(255, 3) + 1;  //とりうる色間距離の最大値より大きい
                  for (int c = 0; c < clusters; ++c) {
                    float dist = dist(rgbList.get(i)[0], rgbList.get(i)[2], rgbList.get(i)[2], aves[c][0], aves[c][1], aves[c][2]);
                    if (dist < minDist) {  //各色と各クラスタの平均色の距離を比較
                      assigns[i] = c;  //現時点で距離が最小ならクラスタの割り当てを更新
                      minDist = dist;
                    }
                  }
                }
                for (int c = 0; c < clusters; ++c)  //空のクラスタが発生した場合にはランダムな色をそのクラスタに再割り当て
                  if (!Arrays.asList(assigns).contains(c))
                    assigns[int(random(assigns.length))] = c;
                if (lastAssigns.equals(assigns))  //クラスタが収束したらクラスタリング終了
                  break;
                loading.progress = float(n) * 100 / loop;  //読み込み画面の進捗度を更新
              }
              float[][] extractedColors = new float[aves.length][];  //抽出した色をHSVで格納する配列
              for (int i = 0; i < extractedColors.length; ++i)
                extractedColors[i] = rgbToHsv(aves[i]);  //各色をRGBに変換して格納
              ArrayList<float[]> sorted = new ArrayList<float[]>();  //平均色の並び変え用ArrayList
              for (int i = 0; i < aves.length; ++i) {  //色の評価値(輝度 - 彩度)が小さい順に並べる
                int position = 0;
                while(sorted.size() > position && sorted.get(position)[2] - sorted.get(position)[1] < extractedColors[i][2] - extractedColors[i][1])
                  position++;  //前の色の評価値 < この色の評価値 <= 後の色の評価値となる番地を計算
                sorted.add(position, extractedColors[i]);  //計算した番地に色を挿入
              }
              for (int i = 0; i < sorted.size(); ++i)  //並べ替えた平均色をパレットに反映
                palette.colors[i] = sorted.get(i);
            } else {  //最も細かい頻度で取得しても取得した色が少なすぎるとき
              toast.show("画像に透過部分が多すぎます");  //トースト表示
              image = null;  //画像を削除
            }
            page.components.remove(loading);  //読み込み画面を破棄
          }
        }
      } catch(IOException e) {
        //println(e);
      }
    }
  }
}

class ColorPicker extends Component {  //カラーピッカー
  int targetColor;  //対応するパレットのスロット
  ImgPanel imagePanel;  //画像操作パネル

  ColorPicker(int id, ImgPanel origin) {
    imagePanel = origin;  //各変数を設定
    cx = imagePanel.cx;
    cy = imagePanel.cy;
    cw = 18;
    ch = 18;
    targetColor = id;
  }
  
  void mouseDragged() {  //マウスがドラッグされたとき
    if (imagePanel.image != null)  //画像が読み込み済みであれば
      setPosition(mouseX - imagePanel.cx - imagePanel.cw / 2 + imagePanel.image.width / 2, mouseY - imagePanel.cy - imagePanel.ch / 2 + imagePanel.image.height / 2);  //マウスの位置にカラーピッカーを移動
  }

  void draw() {
    if (imagePanel.image != null) {  //画像が読み込み済みであれば
      int x = range(cx - imagePanel.cx - imagePanel.cw / 2 + imagePanel.image.width / 2 + cw / 2, 0, imagePanel.image.width - 1);  //正規化した座標を取得
      int y = range(cy - imagePanel.cy - imagePanel.ch / 2 + imagePanel.image.height / 2 + ch / 2, 0, imagePanel.image.height - 1);
      cx = x + imagePanel.cx + imagePanel.cw / 2 - imagePanel.image.width / 2 - cw / 2;  //コンポーネントの座標を更新
      cy = y + imagePanel.cy + imagePanel.ch / 2 - imagePanel.image.height / 2 - ch / 2;
      float[] rgb = hsvToRgb(imagePanel.palette.colors[targetColor]);  //対応する色をRGBで取得
      try {
        int index = y * imagePanel.image.width + x;  //座標に対応するpixels配列の番地
        if (dist(red(imagePanel.image.pixels[index]), green(imagePanel.image.pixels[index]), blue(imagePanel.image.pixels[index]), rgb[0], rgb[1], rgb[2]) >= 1) {  //パレットの色が変更されていれば、パレットの色に最も近い色の座標に移動
          float minDist = pow(255, 3) + 1;  //とりうる色間距離の最大値より大きい
          for (int i = 0; i < imagePanel.image.pixels.length; ++i) {
            if (alpha(imagePanel.image.pixels[i]) == 255) {
              float dist = dist(rgb[0], rgb[1], rgb[2], red(imagePanel.image.pixels[i]), green(imagePanel.image.pixels[i]), blue(imagePanel.image.pixels[i]));  //色間距離を計算
              if (dist < minDist) {  //現時点で距離が最小なら移動
                setPosition(i % imagePanel.image.width, i / imagePanel.image.width);
                minDist = dist;
              }
            }
          }
        }
      } catch (ArrayIndexOutOfBoundsException e) {
        //println(e);
      }
      fill(rgb);  //つまみを描画
      stroke(163);
      strokeWeight(4);
      circle(cx + cw / 2, cy + ch / 2, 16);
      stroke(255);
      strokeWeight(2);
      circle(cx + cw / 2, cy + ch / 2, 16);
    }
  }

  void setPosition(int x, int y) {  //座標を更新しパレットの色を変更する関数
    x = range(x, 0, imagePanel.image.width - 1);  //座標を正規化
    y = range(y, 0, imagePanel.image.height - 1);
    int index = y * imagePanel.image.width + x;  //座標に対応するpixels配列の番地
    imagePanel.palette.colors[targetColor] = rgbToHsv(red(imagePanel.image.pixels[index]), green(imagePanel.image.pixels[index]), blue(imagePanel.image.pixels[index]));  //正規化された座標の色を取得しパレットの色を変更
    cx = x + imagePanel.cx + imagePanel.cw / 2 - imagePanel.image.width / 2 - cw / 2;  //コンポーネントの座標を更新
    cy = y + imagePanel.cy + imagePanel.ch / 2 - imagePanel.image.height / 2 - ch / 2;
  }
}
