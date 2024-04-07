class Home extends Page {  //Homeページのクラス
  ArrayList<Palette> palettes = new ArrayList<Palette>();  //保存したパレットのリスト
  Palette themePalette;  //テーマパレット
  Palette[] recentPalettes = new Palette[2];  //最近更新したパレット
  String loadedFileList;  //最後に取得したファイル一覧
  RecentEdited recentEdited;  //最近更新したパレットを表示するコンポーネントを参照
  AllPalettes allPalettes;  //すべてのパレットを表示するコンポーネントを参照

  Home() {
    if (config[0].isEmpty())  //パレットの保存先が設定されていなければ ユーザーホームディレクトリ/Palettes に設定
      config[0] = System.getProperty("user.home") + "/Palettes";
    Path palettesPath = Paths.get(config[0]);
    if (!Files.exists(palettesPath)) {  //Palettesフォルダが存在しなければ
      try {
        Files.createDirectory(palettesPath);  //Palettsフォルダを作成
        File[] p4ls = new File(dataPath("samplePalettes")).listFiles();  //サンプルパレットをコピー
        for (int i = 0; i < p4ls.length; ++i)
          if (p4ls[i].isFile() && p4ls[i].getName().endsWith(".p4l"))
            Files.copy(Paths.get(p4ls[i].getPath()), Paths.get(config[0] + "/" + p4ls[i].getName()));
      } catch(IOException e) {
        //println(e);
      }
    }
    saveStrings("config.csv", config);  //設定ファイルを更新
    recentEdited = new RecentEdited(30, 170, 420, 84);  //最近更新されたパレットを表示するコンポーネントのインスタンスを作成
    allPalettes = new AllPalettes(30, 312, 440, 378, palettes);  //すべてのパレットを表示するコンポーネントのインスタンスを作成
    loadPalettes();  //パレットを読み込む
    if (palettes.size() > 0)  //パレットがあればその中からランダムでテーマパレットを選択
      themePalette = palettes.get(int(random(palettes.size())));
    else  //なければデフォルトパレットをテーマパレットに設定
      themePalette = new Palette("default palette", new Timestamp(System.currentTimeMillis()), new float[][]{{339, 74, 94}, {237, 98, 85}, {204, 97, 94}, {55, 97, 94}, {50, 97, 94}});
    components.add(new Colors(0, 0, 480, 144, themePalette.colors));  //各コンポーネントを作成しコンポーネントのリストに追加
    components.add(new Logo(30, 32, 1));
    components.add(new MakePalette(280, 36, 170, 30, themePalette.colors));
    components.add(new PalettesBoard(0, 100, 480, 620));
    components.add(recentEdited);
    components.add(allPalettes);
  }

  void draw() {
    String fileList = "";  //パレットの追加・削除を監視して、変更があれば再読み込み
    File[] p4ls = new File(config[0]).listFiles();
    if (p4ls != null) {
      for (int i = 0; i < p4ls.length; ++i) {  //ファイルリストを作成
        if (p4ls[i].isFile() && p4ls[i].getName().endsWith(".p4l")) {
          fileList += p4ls[i].getPath();
        }
      }
    }
    if (!loadedFileList.equals(fileList))  //最後にパレットを読み込んだときのファイルリストと比較
      loadPalettes();  //パレットを再読み込み
    drawComponents();  //子コンポーネントを描画
  }

  void loadPalettes() {  //パレットを読み込む関数
    palettes.clear();  //パレットリストを初期化
    recentPalettes = new Palette[2];  //最近更新したパレットを初期化
    recentEdited.components.clear();  //最近更新したパレットを表示するコンポーネントのコンポーネントを削除
    loadedFileList = "";
    File[] p4ls = new File(config[0]).listFiles();  //保存先フォルダ内のファイル一覧を取得
    if (p4ls != null) {  //正常に取得できていれば
      for (int i = 0; i < p4ls.length; ++i) {
        if (p4ls[i].isFile() && p4ls[i].getName().endsWith(".p4l")) {  //.p4lファイルであれば読み込み済みファイルリストに追加して読み込む
          loadedFileList += p4ls[i].getPath();
          String[] paletteData = loadStrings(p4ls[i].getAbsolutePath());  //拡張子をのぞいたファイル名を取得
          String[] fileNameFrag = split(p4ls[i].getName(), ".");
          String fileName = join(Arrays.copyOf(fileNameFrag, fileNameFrag.length - 1), ".");
          if (paletteData != null && paletteData.length >= 2 && paletteData[0].equals("P4LETTE")) {  //このファイルがP4LETTEファイルであると宣言していて、バージョン情報が含まれるときは続行
            if (paletteData[1].equals("1.0") && paletteData.length == 9) {  //古い形式のファイルは新しい形式に合うように変換
              String[] newPaletteData = new String[8];
              newPaletteData[0] = "P4LETTE";
              newPaletteData[1] = "1.1";
              newPaletteData[2] = paletteData[3];
              for (int j = 0; j < 5; ++j)
                newPaletteData[j + 3] = paletteData[j + 4];
              paletteData = newPaletteData;
              saveStrings(p4ls[i].getAbsolutePath(), paletteData);
            }
            if (paletteData[1].equals("1.1") && paletteData.length == 8 && fileName.length() <= 50 && paletteData[2].matches("\\d{4}-\\d{2}-\\d{2}\\s\\d{2}:\\d{2}:\\d{2}(\\.\\d+)?")) {  //現時点で有効なファイルであれば読み込みを続行
              float[][] colors = new float[5][3];
              boolean illegal = false;
              for (int j = 0; j < colors.length; ++j) {
                String[] rgbStrings = split(paletteData[j + 3], ",");
                if (rgbStrings.length == colors[j].length) {  //現時点で有効なファイルであれば読み込みを続行
                  float[] rgb = new float[rgbStrings.length];
                  for (int k = 0; k < rgb.length; ++k) {
                    if (rgbStrings[k].matches("\\d*(\\.\\d+)?"))  //現時点で有効なファイルであれば読み込みを続行
                      rgb[k] = range(Float.valueOf(rgbStrings[k]), 0, 255);
                    else {
                      illegal = true;
                      break;
                    }
                  }
                  if (!illegal) colors[j] = rgbToHsv(rgb);  //現時点で有効なファイルであれば読み込みを続行
                } else {
                  illegal = true;
                  break;
                }
              }
              if (illegal) continue;  //無効なファイルであればこのファイルの読み込みを中止
              Palette palette = new Palette(fileName, Timestamp.valueOf(paletteData[2]), colors);  //読み込んだデータをもとにPaletteインスタンスを作成
              palettes.add(palette);  //パレットリストに追加
              if (recentPalettes[0] == null || palette.timestamp.after(recentPalettes[0].timestamp)) {  //1番目に新しいファイルかどうかのチェック
                recentPalettes[1] = recentPalettes[0];  //1番目に新しかったパレットを2番目に移動
                recentPalettes[0] = palette;  //1番目に新しいパレットを更新
              } else if (recentPalettes[1] == null || palette.timestamp.after(recentPalettes[1].timestamp))  //2番目に新しいファイルかどうかのチェック
                recentPalettes[1] = palette;  //2番目に新しいパレットを更新
            }
          }
        }
      }
      for (int i = 0; i < recentPalettes.length; ++i)  //最近更新したパレットを最近更新したパレットを表示するコンポーネントに追加
        if (recentPalettes[i] != null)
          recentEdited.addPalette(i, recentPalettes[i]);
    }
    allPalettes.loadPalettes();  //すべてのパレットコンポーネントにパレットを読み込み
  }
}

class RecentEdited extends Component {  //最近更新したパレットを表示するコンポーネント
  RecentEdited(int x, int y, int w, int h) {
    cx = x;  //各変数を設定
    cy = y;
    cw = w;
    ch = h;
  }

  void addPalette(int index, Palette palette) {  //パレットを追加する関数
    components.add(new PaletteSample(cx + (cw / 2 + 10) * index, cy, cw / 2 - 10, ch, palette));  //パレットのサンプルを生成しコンポーネントのリストに追加
  }
}

class AllPalettes extends ScrollBox {  //すべてのパレットを表示するコンポーネント
  ArrayList<Palette> palettes;  //パレットのリスト

  AllPalettes(int x, int y, int w, int h, ArrayList<Palette> allPalettes) {
    cx = x;  //各変数を設定
    cy = y;
    cw = w;
    ch = h;
    palettes = allPalettes;
    loadPalettes();
  }

  void loadPalettes() {  //パレットを読み込む関数
    scrollY = 0;  //スクロールをリセット
    components.clear();  //コンポーネントのリストを再設定
    for (int i = 0; i < palettes.size(); ++i) {
      if (i % 2 == 0)  //パレットのサンプルを左右に配置
        components.add(new PaletteSample(30, 312 + 108 * i / 2, 200, 84, palettes.get(i)));
      else
        components.add(new PaletteSample(250, 312 + 108 * (i - 1) / 2, 200, 84, palettes.get(i)));
    }
  }
}

class Logo extends Component {  //ロゴのコンポーネント
  Logo(int x, int y, float zoom) {  //zoom: 画像の倍率
    cx = x;  //各変数を設定
    cy = y;
    cw = int(logo.width * zoom);  //引数に設定した倍率に応じてコンポーネントのサイズを計算
    ch = int(logo.height * zoom);
  }
  
  void draw() {
    image(logo, cx, cy, cw, ch);  //画像を描画
  }
}

class MakePalette extends Component {  //パレット作成ボタンのコンポーネント
  float[][] colors;  //テーマパレットの色リスト
  float[] textRgb;  //テキストの色

  MakePalette(int x, int y, int w, int h, float[][] themeColors) {  //themeColors: テーマパレットの色リスト
    cx = x;  //各変数を設定
    cy = y;
    cw = w;
    ch = h;
    colors = themeColors;
    float minV = 100;
    for (int i = 0; i < colors.length; ++i) {  //テーマパレットで最も暗い色を文字の色に設定
      if (colors[i][2] <= minV) {
        textRgb = hsvToRgb(colors[i]);  //HSVをRGBに変換
        minV = colors[i][2];
      }
    }
  }

  void draw() {
    noStroke();  //背景を描画
    fill(255);
    rect(cx, cy, cw, ch, ch / 2);
    fill(textRgb);  //テキストを描画
    textFont(NotoSans_m);
    textSize(14);
    textAlign(CENTER, CENTER);
    text("新しく作成", cx + cw / 2, cy + ch / 2);
  }

  void mouseClicked() {  //クリックされたときの処理
    String title = "新規パレット";
    if (Files.exists(Paths.get(config[0] + "/" + title + ".p4l"))) {  //「新規パレット」が既に存在するときには「新規パレット(n)」にする
      int i = 0;
      while (Files.exists(Paths.get(config[0] + "/" + title + "(" + ++i + ").p4l")));
      title = title + "(" + i + ")";
    }
    page = new Editor(title, colors, true);  //Editorページに遷移
  }
}

class PalettesBoard extends Component {  //パレット一覧を表示する土台のコンポーネント
  PalettesBoard(int x, int y, int w, int h) {
    cx = x;  //各変数を設定
    cy = y;
    cw = w;
    ch = h;
  }

  void draw() {
    noStroke();  //背景を描画
    fill(255);
    rect(cx, cy, cw, ch, 30, 30, 0, 0);
    fill(18);  //テキストを描画
    textFont(NotoSans_m);
    textSize(18);
    textAlign(LEFT, TOP);
    text("最近使用したパレット", 30, 136);
    text("すべてのパレット", 30, 278);
  }
}

class PaletteSample extends Component {  //各パレットのサンプルを表示するコンポーネント
  Palette palette;  //パレットを保持
  Colors colors;  //色リストのコンポーネント

  PaletteSample(int x, int y, int w, int h, Palette defaultPalette) {  //defaultPalette: 表示するパレットの初期値
    cx = x;  //各変数を設定
    cy = y;
    cw = w;
    ch = h;
    palette = defaultPalette;
    colors = new Colors(cx, cy, cw, ch - 24, palette.colors);  //色リストのコンポーネントを作成
    components.add(colors);  //コンポーネントのリストに追加
  }

  void draw() {
    colors.cx = cx;  //このコンポーネントの座標が更新されたら色リストの座標も更新
    colors.cy = cy;
    drawComponents();  //子コンポーネントを描画
    fill(18);  //パレットのタイトルを描画
    textFont(NotoSans_r);
    textSize(14);
    textAlign(LEFT, BOTTOM);
    String titlePreview = palette.title;
    if (textWidth(titlePreview) > cw) {  //パレットのタイトルが長いときには省略
      while (textWidth(titlePreview + "…") > cw)
        titlePreview = titlePreview.substring(0, titlePreview.length() - 1);
      titlePreview += "…";
    }
    text(titlePreview, cx, cy + ch);
  }

  void mouseClicked() {  //クリックされたときの処理
    page = new Editor(palette.title, palette.colors, false);  //Editorページに遷移
  }
}
