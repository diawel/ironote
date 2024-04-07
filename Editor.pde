class Editor extends Page implements DialogObserver {  //Editorページのクラス
  EditedPalette palette;  //編集中のパレット
  EditedPalette savedPalette;  //最後に保存したパレット

  Editor(String defaultTitle, float[][] defaultColors, boolean newPalette) {  //defaultTitle: パレットのタイトルの初期値, defaultColors: パレットの色の初期値, newPalette: 新規パレットかどうか
    float[][] mutableColors = new float[defaultColors.length][];  //defaultColorsをディープコピー
    for(int i = 0; i < defaultColors.length; ++i)
      mutableColors[i] = defaultColors[i].clone();
    palette = new EditedPalette(defaultTitle, mutableColors);  //編集されるパレットを作成
    if (!newPalette)  //新規パレットでなければ保存済みパレットを作成
      savedPalette = new EditedPalette(defaultTitle, defaultColors);
    TabGroup tabGroup = new TabGroup(30, 76, 420, 436);  //タブグループを作成
    components.add(tabGroup);
    Tab colorWheelTab = new Tab("カラーホイール");  //カラーホイールタブを作成
    tabGroup.tabs.add(colorWheelTab);  //タブをタブグループに追加
    colorWheelTab.components.add(new ColorPanel(30, 76, 420, 396, palette));  //各コンポーネントを作成しタブのコンポーネントのリストに追加
    colorWheelTab.components.add(new ColorWheel(68, 108, 128, palette));
    colorWheelTab.components.add(new BrightnessBar(364, 108, 30, 256, palette));
    colorWheelTab.components.add(new Rgb(60, 388, palette));
    colorWheelTab.components.add(new Hsv(256, 388, palette));
    colorWheelTab.components.add(new Hex(60, 428, palette));
    Tab analizeImgTab = new Tab("画像から抽出");  //画像から抽出タブを作成
    tabGroup.tabs.add(analizeImgTab);  //タブをタブグループに追加
    analizeImgTab.components.add(new ImgPanel(30, 76, 420, 396, palette));  //各コンポーネントを作成しコンポーネントのリストに追加
    components.add(new TabSelector(30, 24, 420, 30, tabGroup));
    components.add(new ColorSelector(30, 512, 420, 84, palette));
    components.add(new Title(30, 608, 420, 22, palette));
    components.add(new Save(30, 654, 200, 36, this));
    components.add(new Delete(250, 654, 200, 36, this));
    components.add(new Close(420, 18, 1, this));
  }
  
  void save() {  //パレットを保存する関数
    delete();  //保存済みのパレットを削除
    String[] paletteData = new String[8];  //パレットの文字列データを作成
    paletteData[0] = "P4LETTE";
    paletteData[1] = "1.1";
    paletteData[2] = String.valueOf(new Timestamp(System.currentTimeMillis()));  //現在時刻からタイムスタンプを生成
    for (int i = 0; i < palette.colors.length; ++i) {  //色はRGBに変換して保存
      float[] rgb = hsvToRgb(palette.colors[i]);
      String[] rgbStrings = new String[rgb.length];
      for (int j = 0; j < rgbStrings.length; ++j)
        rgbStrings[j] = String.valueOf(rgb[j]);
      paletteData[i + 3] = join(rgbStrings, ",");
    }
    saveStrings(config[0] + "/" + palette.title + ".p4l", paletteData);  //設定されたフォルダに保存
    float[][] savedColors = new float[palette.colors.length][];  //編集中のパレットの色をディープコピー
    for(int i = 0; i < palette.colors.length; ++i)
      savedColors[i] =  palette.colors[i].clone();
    savedPalette = new EditedPalette(palette.title, savedColors);  //最後に保存したパレットを更新
    components.add(new ShareDialog(this));
  }

  void delete() {  //パレットを削除する関数
    if (savedPalette != null) {  //パレットを保存済みであればファイルを削除
      Path palettePath = Paths.get(config[0] + "/" + savedPalette.title + ".p4l");
      if (Files.exists(palettePath)) {
        try {
          Files.delete(palettePath);
        } catch(IOException e) {
          //println(e);
        }
      }
    }
  }

  void share() {  //パレットを共有する関数
    String[] paletteData = new String[7];  //ファイルバージョン、タイトル、色のリストを配列に文字列として格納
    paletteData[0] = "1.0";
    paletteData[1] = palette.title;
    for (int i = 0; i < palette.colors.length; ++i) {  //色はRGBに変換
      float[] rgb = hsvToRgb(palette.colors[i]);
      String[] rgbStrings = new String[rgb.length];
      for (int j = 0; j < rgbStrings.length; ++j)
        rgbStrings[j] = String.valueOf(rgb[j]);
      paletteData[i + 2] = join(rgbStrings, ",");
    }
    Charset UTF_8 = StandardCharsets.UTF_8;  //文字列を改行区切りでつなげBase64 URLにエンコード 参考: https://qiita.com/clomie/items/ea2ce6080eed5f5fa9ef
    String base64 = new String(Base64.getUrlEncoder().withoutPadding().encode(join(paletteData, "\n").getBytes(UTF_8)), UTF_8);
    StringSelection stringSelection = new StringSelection("https://ironote.diawel.me/share?d=" + base64);  //エンコードした文字列をパラメータとしたURLをクリップボードにコピー
    Toolkit.getDefaultToolkit().getSystemClipboard().setContents(stringSelection, stringSelection);
    toast.show("リンクをコピーしました");  //トースト表示
  }

  void close() {  //Editorページを閉じる関数
    page = new Home();
  }

  void onclose(Dialog instance) {  //管理するダイアログが閉じられたときに呼び出される関数
    components.remove(instance);  //閉じられたダイアログをコンポーネントリストから削除
  }
}

class EditedPalette {  //編集中パレットのデータを扱うクラス
  String title;  //パレットのタイトル
  float[][] colors;  //パレットの色
  int editedColor;  //編集中の色のインデックス

  EditedPalette(String defaultTitle, float[][] defaultColors) {  //defaultTitle: タイトルの初期値, defaultColors: 色リストの初期値
    title = defaultTitle;  //各変数を設定
    colors = defaultColors;
    editedColor = 0;  //編集中の色のインデックスを初期化
  }

  float[] editedColor() {  //編集中の色を取得する関数
    return colors[editedColor];  //編集中の色を返す
  }

  void updateEditedColor(float[] updatedColor) {  //編集中の色を更新する関数  updatedColor:変更された色
    colors[editedColor] = updatedColor;
  }
}

class ColorSelector extends Component {  //編集する色を選ぶコンポーネント
  Colors colors;  //色リストのコンポーネント
  EditedPalette palette;  //編集中のパレット

  ColorSelector(int x, int y, int w, int h, EditedPalette editedPalette) {  //editedPalette: 編集中のパレット
    cx = x;  //各変数を設定
    cy = y;
    cw = w;
    ch = h;
    palette = editedPalette;
    colors = new Colors(cx, cy, cw, ch, palette.colors);  //色リストのコンポーネントを作成
    components.add(colors);  //色リストのコンポーネントをコンポーネントのリストに追加
  }

  void mouseClicked() {  //クリックされたら編集中の色をクリックされた色に変更
    palette.editedColor = (mouseX - cx) * palette.colors.length / cw;
  }
}

class Title extends Component implements TextInputObserver {  //パレットのタイトルの入力欄のコンポーネント
  TextInput textInput;  //テキスト入力欄
  EditedPalette palette;  //編集中のパレット

  Title(int x, int y, int w, int h, EditedPalette editedPalette) {  //editedPalette: 編集中のパレット
    cx = x;  //各変数を設定
    cy = y;
    cw = w;
    ch = h;
    palette = editedPalette;
    textInput = new TextInput(cx, cy, cw, ch, this, null);
    components.add(textInput);
  }

  void draw() {
    if (!textInput.isSelected)  //入力中以外は編集中のパレットのデータに基づいた値を設定
      textInput.value = palette.title;
    drawComponents();  //子コンポーネントを描画
  }

  void onblur(TextInput instance) {  //テキスト入力欄の選択が解除されたら
    String validatedTitle = instance.value.replaceAll("[\\\\/:\\*\\?\"<>\\|]", "");  //ファイル名に使用できない文字を削除
    if (validatedTitle.length() > 50)  //50文字を超える部分を削除
      validatedTitle = validatedTitle.substring(0, 50);
    palette.title = validatedTitle;  //編集中のパレットのタイトルを入力された文字列(を正規化したもの)に変更
  }
}

class Save extends Component implements ButtonObserver {  //保存ボタンのコンポーネント
  Editor editor;  //Editorページ

  Save(int x, int y, int w, int h, Editor origin) {
    cx = x;  //各変数を設定
    cy = y;
    cw = w;
    ch = h;
    editor = origin;
    components.add(new BlackButton(cx, cy, cw, ch, "保存", this));
  }

  void onclick(Button instance) {  //クリックされたときに呼び出される関数
    if (editor.palette.title.length() > 0) {  //タイトルが入力されていたら
      if ((editor.savedPalette == null && !Files.exists(Paths.get(config[0] + "/" + editor.palette.title + ".p4l"))) || (editor.savedPalette != null && editor.savedPalette.title.equals(editor.palette.title) && Arrays.deepEquals(editor.savedPalette.colors, editor.palette.colors)))
        editor.save();  //更新されていないか、新規パレットでかつ既存のパレットとタイトルがかぶっていなければ上書き保存
      else  
        editor.components.add(new SaveDialog(editor));  //上書き保存を行うときには確認ダイアログを表示
    } else
      toast.show("タイトルを入力してください");  //タイトルが入力されていなければトースト表示
  }
}

class Delete extends Component implements ButtonObserver {  //削除ボタンのコンポーネント
  Editor editor;  //Editorページ

  Delete(int x, int y, int w, int h, Editor origin) {
    cx = x;  //各変数を設定
    cy = y;
    cw = w;
    ch = h;
    editor = origin;
    components.add(new WhiteButton(cx, cy, cw, ch, "削除", this));
  }

  void onclick(Button instance) {  //クリックされたときに呼び出される関数
    editor.components.add(new DeleteDialog(editor));  //確認ダイアログを表示
  }
}

class Close extends Component {  //閉じるボタンのコンポーネント
  Editor editor;  //Editorページ

  Close(int x, int y, float zoom, Editor origin) {  //zoom: 画像の倍率, origin: Editorページ
    cx = x;  //各変数を設定
    cy = y;
    editor = origin;
    cw = int(close.width * zoom);  //引数に設定した倍率に応じてコンポーネントのサイズを計算
    ch = int(close.height * zoom);
  }
  
  void draw() {
    image(close, cx, cy, cw, ch);  //閉じるボタンを描画
  }

  void mouseClicked() {  //クリックされたときに呼び出される関数
    if (editor.savedPalette != null && editor.savedPalette.title.equals(editor.palette.title) && Arrays.deepEquals(editor.savedPalette.colors, editor.palette.colors))
      editor.close();  //パレットを保存済みであればEditorページを閉じる
    else
      editor.components.add(new CloseDialog(editor));  //パレットに変更があれば確認ダイアログを表示
  }
}

class SaveDialog extends Dialog implements ButtonObserver {  //上書き保存確認ダイアログ
  Button[] buttons = new Button[2];  //2つのボタンのコンポーネント
  Editor editor;  //Editorページ

  SaveDialog(Editor origin) {  //origin: Editorページ
    cx = 0;  //各変数を設定
    cy = 0;
    cw = width;
    ch = height;
    bx = 30;
    by = 304;
    bw = 420;
    bh = 110;
    editor = origin;
    observer = editor;
    components.add(new Text(56, 332, 22, NotoSans_m, "上書き保存しますか？"));  //テキストコンポーネントを作成
    buttons[0] = new TextButton(294, 378, 18, NotoSans_r, "保存", this);  //2つのボタンを生成
    buttons[1] = new TextButton(340, 378, 18, NotoSans_r, "キャンセル", this);
    for (int i = 0; i < buttons.length; ++i)  //各コンポーネントをコンポーネントのリストに追加
      components.add(buttons[i]);
  }

  void onclick(Button instance) {  //ボタンがクリックされたときに呼び出される関数
    for (int i = 0; i < buttons.length; ++i) {
      if (buttons[i] == instance) {
        switch (i) {  //クリックされたボタンごとの処理
          case 0:  //保存
            editor.save();  //パレットを保存する
          case 1:  //キャンセル
            close();  //ダイアログを閉じる
            break;
        }
      }
    }
  }
}

class DeleteDialog extends Dialog implements ButtonObserver {
  Button[] buttons = new Button[2];  //2つのボタンのコンポーネント
  Editor editor;  //Editorページ

  DeleteDialog(Editor origin) {  //origin: Editorページ
    cx = 0;  //各変数を設定
    cy = 0;
    cw = width;
    ch = height;
    bx = 30;
    by = 304;
    bw = 420;
    bh = 110;
    editor = origin;
    observer = editor;
    components.add(new Text(56, 332, 22, NotoSans_m, "本当に削除しますか？"));  //テキストコンポーネントを作成
    buttons[0] = new TextButton(294, 378, 18, NotoSans_r, "削除", this);  //2つのボタンを生成
    buttons[1] = new TextButton(340, 378, 18, NotoSans_r, "キャンセル", this);
    for (int i = 0; i < buttons.length; ++i)  //各コンポーネントをコンポーネントのリストに追加
      components.add(buttons[i]);
  }

  void onclick(Button instance) {  //ボタンがクリックされたときに呼び出される関数
    for (int i = 0; i < buttons.length; ++i) {
      if (buttons[i] == instance) {
        switch (i) {  //クリックされたボタンごとの処理
          case 0:  //削除
            editor.delete();  //パレットを削除して
            editor.close();  //Editorページを閉じる
          case 1:  //キャンセル
            close();  //ダイアログを閉じる
            break;
        }
      }
    }
  }
}

class CloseDialog extends Dialog implements ButtonObserver {  //編集画面離脱確認ダイアログ
  Button[] buttons = new Button[3];  //3つのボタン
  Editor editor;  //Editorページ

  CloseDialog(Editor origin) {  //origin: Editorページ
    cx = 0;  //各変数を設定
    cy = 0;
    cw = width;
    ch = height;
    bx = 30;
    by = 304;
    bw = 420;
    bh = 110;
    editor = origin;
    observer = editor;
    components.add(new Text(56, 332, 22, NotoSans_m, "変更を保存しますか？"));  //テキストコンポーネントを作成
    buttons[0] = new TextButton(194, 378, 18, NotoSans_r, "保存", this);  //3つのボタンを生成
    buttons[1] = new TextButton(240, 378, 18, NotoSans_r, "保存しない", this);
    buttons[2] = new TextButton(340, 378, 18, NotoSans_r, "キャンセル", this);
    for (int i = 0; i < buttons.length; ++i)  //各コンポーネントをコンポーネントのリストに追加
      components.add(buttons[i]);
  }

  void onclick(Button instance) {  //ボタンがクリックされたときに呼び出される関数
    for (int i = 0; i < buttons.length; ++i) {
      if (buttons[i] == instance) {
        switch (i) {  //クリックされたボタンごとの処理
          case 0:  //保存
            editor.save();  //パレットを保存
          case 1:  //保存しない
            editor.close();  //Editorページを閉じる
            break;
          case 2:  //キャンセル
            close();  //ダイアログを閉じる
            break;
        }
      }
    }
  }
}

class ShareDialog extends Dialog implements ButtonObserver {  //共有ダイアログ
  Button[] buttons = new Button[2];  //2つのボタン
  Editor editor;  //Editorページ

  ShareDialog(Editor origin) {  //origin: Editorページ
    cx = 0;  //各変数を設定
    cy = 0;
    cw = width;
    ch = height;
    bx = 30;
    by = 224;
    bw = 420;
    bh = 272;
    editor = origin;
    observer = editor;
    components.add(new Text(56, 252, 22, NotoSans_m, "パレットを保存しました！"));  //テキストコンポーネントを作成
    components.add(new SavedPalette(56, 294, 368, 144, editor.palette));  //パレットのプレビューを生成
    buttons[0] = new TextButton(306, 460, 18, NotoSans_r, "シェア", this);  //2つのボタンを生成
    buttons[1] = new TextButton(370, 460, 18, NotoSans_r, "閉じる", this);
    for (int i = 0; i < buttons.length; ++i)  //各コンポーネントをコンポーネントのリストに追加
      components.add(buttons[i]);
  }

  void onclick(Button instance) {  //ボタンがクリックされたときに呼び出される関数
    for (int i = 0; i < buttons.length; ++i) {
      if (buttons[i] == instance) {
        switch (i) {  //クリックされたボタンごとの処理
          case 0:  //シェア
            editor.share();  //パレットをシェアして
            close();  //ダイアログを閉じる
            break;
          case 1:  //閉じる
            close();  //ダイアログを閉じる
            break;
        }
      }
    }
  }
}

class SavedPalette extends Component {  //保存済みパレットのコンポーネント
  EditedPalette palette;  //表示するパレット

  SavedPalette(int x, int y, int w, int h, EditedPalette defaultPalette) {  //defaultPalette: 表示するパレット
    cx = x;  //各変数を設定
    cy = y;
    cw = w;
    ch = h;
    palette = defaultPalette;
    components.add(new Colors(cx, cy, cw, ch - 34, palette.colors));  //色リストのコンポーネントを作成しコンポーネントのリストに追加
  }

  void draw() {
    drawComponents();  //子コンポーネントを描画
    textAlign(LEFT, BOTTOM);  //タイトルを描画
    fill(18);
    textFont(NotoSans_r);
    textSize(22);
    String titlePreview = palette.title;
    if (textWidth(titlePreview) > cw) {  //タイトルが長い時には省略
      while (textWidth(titlePreview + "…") > cw)
        titlePreview = titlePreview.substring(0, titlePreview.length() - 1);
      titlePreview += "…";
    }
    text(titlePreview, cx, cy + ch);
  }
}
