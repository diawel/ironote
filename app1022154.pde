//ライブラリのインポート
import java.nio.file.Path;
import java.nio.file.Paths;
import java.nio.file.Files;
import java.nio.charset.Charset;
import java.nio.charset.StandardCharsets;
import java.sql.Timestamp;
import java.awt.Toolkit;
import java.awt.datatransfer.Clipboard;
import java.awt.datatransfer.DataFlavor;
import java.awt.datatransfer.StringSelection;
import java.awt.datatransfer.UnsupportedFlavorException;
import java.util.regex.Matcher;
import java.util.regex.Pattern;
import java.util.Arrays;
import java.util.Base64;

Page page;  //現在のページを参照
PFont NotoSans_r, NotoSans_m;  //各フォント
PImage logo, close;  //各画像
String[] config;  //設定ファイル
TextInput selectedTextInput;  //選択中のテキスト入力欄を参照
FileObserver handlingFileObsever;  //現在のファイル選択を管理するインスタンスを参照
Toast toast;  //トースト表示を参照

void setup() {
  size(480, 720);  //ウィンドウサイズ設定
  NotoSans_r = createFont("font/NotoSansJP/Regular.otf", 240);  //フォントを読み込み
  NotoSans_m = createFont("font/NotoSansJP/Medium.otf", 240);
  logo = loadImage("img/logo.png");  //画像を読み込み
  close = loadImage("img/close.png");
  config = loadStrings("config.csv");  //設定ファイル読み込み
  page = new Home();  //Homeページに遷移
  toast = new Toast();  //トースト表示を初期化
}

void draw() {
  background(245);  //背景を描画
  page.draw();  //現在のページを描画
  toast.draw();  //トースト表示を更新
}

void mouseClicked() {
  page.mouseClicked();  //クリックをページに伝達
}

void mousePressed() {
  if (selectedTextInput != null)  //テキスト入力中にテキスト入力欄以外をクリックしたときに、その入力欄の選択を解除
    if (!isOver(selectedTextInput.cx, selectedTextInput.cy, selectedTextInput.cw, selectedTextInput.ch, mouseX, mouseY, 0, 0))
      selectedTextInput.onblur();
  page.mousePressed();  //マウス押下をページに伝達
}

void mouseDragged() {
  page.mouseDragged();  //ドラッグをページに伝達
}

void mouseReleased() {
  page.mouseReleased();  //マウス解放をページに伝達
}

void mouseWheel(MouseEvent event) {
  page.mouseWheel(event);  //スクロールをページに伝達
}

void keyPressed() {
  if (selectedTextInput != null)  //テキスト入力中であれば、入力欄にキー押下を伝達
    selectedTextInput.keyPressed();
}

void keyTyped() {
  if (selectedTextInput != null)  //テキスト入力中であれば、入力欄にキー入力を伝達
    selectedTextInput.keyTyped();
}

void fileSelected(File input) {
  if (handlingFileObsever != null) {
    handlingFileObsever.fileSelected(input);  //ファイル選択画面の呼び出し元にファイルを伝達
    handlingFileObsever = null;  //ファイル選択を管理するインスタンスの参照を解除
  }
}

class Palette {  //パレットのデータを扱うクラス
  String title;  //パレットのタイトル
  Timestamp timestamp;  //パレットの更新日時
  float[][] colors;  //パレットの色

  Palette(String defaultTitle, Timestamp defaultTimestamp, float[][] defaultColors) {  //defaultTitle: タイトルの初期値, defaultTimestamp: 更新日時の初期値, defaultColors: 色の初期値
    title = defaultTitle;
    timestamp = defaultTimestamp;
    colors = defaultColors;
  }
}

class Page {  //ページ以下のUIに共通のクラス
  ArrayList<Component> components = new ArrayList<Component>();  //コンポーネント(各UI)のリスト
  Component handlingComponent;  //操作対象のコンポーネントを参照

  void draw() {
    drawComponents();  //子コンポーネントを描画
  }

  void drawComponents() {  //子コンポーネントを描画する関数
    for (int i = 0; i < components.size(); ++i)
      components.get(i).draw();
  }

  Component getHandlingComponent(int x, int y) {  //引数に指定した座標にあるコンポーネントを取得する関数
    for (int i = components.size() - 1; i >= 0; --i) {  //コンポーネントのリストを後ろから検索(リストの後ろにあるものが前面に描画されるため)
      Component component = components.get(i);
      if (isOver(component.cx, component.cy, component.cw, component.ch, x, y, 0, 0)) {
        return component;  //指定された座標にあるコンポーネントを返す
      }
    }
    return null;
  }

  void mouseClicked() {
    Component target = getHandlingComponent(mouseX, mouseY);  //クリックされたコンポーネントを取得
    if (target != null) target.mouseClicked();  //クリックされたコンポーネントにクリックを伝達
  }

  void mousePressed() {
    handlingComponent = getHandlingComponent(mouseX, mouseY);  //操作対象のコンポーネントを更新
    if (handlingComponent != null) handlingComponent.mousePressed();  //マウス押下されたコンポーネントにマウス押下を伝達
  }

  void mouseDragged() {
    if (handlingComponent != null) handlingComponent.mouseDragged();  //ドラッグされたコンポーネントにドラッグを伝達
  }

  void mouseReleased() {
    if (handlingComponent != null) {
      handlingComponent.mouseReleased();  //マウス解放されたコンポーネントにマウス解放を伝達
      handlingComponent = null;  //操作対象のコンポーネントの参照を解除
    }
  }

  void mouseWheel(MouseEvent event) {
    Component target = getHandlingComponent(mouseX, mouseY);  //スクロールされたコンポーネントを取得
    if (target != null) target.mouseWheel(event);  //スクロールされたコンポーネントにスクロールを伝達
  }
}

interface FileObserver {  //ファイル選択を管理するクラスに実装するインターフェース
  void fileSelected(File input);  //ファイルが選択されたときに呼び出される関数
}

class Toast {  //トースト表示を扱うクラス
  String text;  //表示内容
  int timeout;  //消滅する時間

  Toast() {
    text = "";  //初期化
  }

  void show(String value) {  //トーストを表示する関数 value: 表示内容
    text = value;
    timeout = millis() + 3000;  //3000msで表示終了
  }

  void draw() {
    if (millis() < timeout) {  //トースト表示を描画
      noStroke();  //背景を描画
      fill(0, 128);
      textFont(NotoSans_m);
      textSize(18);
      float textWidth = textWidth(text);  //表示内容のテキストの幅を取得し、それに応じて背景のサイズを計算
      rect(width / 2 - textWidth / 2 - 10, height / 2 - 13, textWidth + 20, 26, 8);
      fill(255);  //テキストを描画
      textAlign(CENTER, CENTER);
      text(text, width / 2, height / 2);
    }
  }
}
