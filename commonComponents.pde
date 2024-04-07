class Component extends Page {  //各UIに相当するクラス
  int cx, cy, cw, ch;  //コンポーネントの位置と大きさ
}

class Colors extends Component {  //複数の色の長方形が均等に横並びになったコンポーネント
  float[][] colors;  //表示する色のリスト

  Colors(int x, int y, int w, int h, float[][] defaultColors) {  //defaultColors: 表示する色のリストの初期値
    cx = x;  //各変数を設定
    cy = y;
    cw = w;
    ch = h;
    colors = defaultColors;
  }

  void draw() {
    noStroke();  //各色を描画
    for (int i = 0; i < colors.length; ++i) {
      fill(hsvToRgb(colors[i]));
      rect(cx + cw / colors.length * i, cy, cw / colors.length, ch);
    }
  }
}

class Text extends Component {  //テキストを表示するコンポーネント
  float textSize;  //フォントサイズ
  String text;  //表示するテキスト
  PFont font;  //フォント

  Text(int x, int y, float defaultTextSize, PFont defaultFont, String defaultText) {  //defaultTextSize: フォントサイズの初期値, defaultFont: フォントの初期値, defaultText: テキストの初期値
    cx = x;  //各変数を設定
    cy = y;
    textSize = defaultTextSize;
    font = defaultFont;
    text = defaultText;
    ch = ceil(textSize);  //フォントサイズをもとにコンポーネントのサイズを設定
    textFont(font);
    textSize(textSize);
    cw = ceil(textWidth(text));  //表示するテキストをもとにコンポーネントのサイズを設定
  }

  void draw() {
    fill(18);  //テキストを描画
    textFont(font);
    textSize(textSize);
    textAlign(LEFT, TOP);
    text(text, cx, cy);
  }
}

class Button extends Component {  //ボタンコンポーネントに共通したクラス
  String value;  //表示内容
  ButtonObserver observer;  //ボタンを管理するインスタンスを参照

  void mouseClicked() {  //クリックされたら
    observer.onclick(this);  //ボタンを管理するインスタンスのonclickを呼び出す
  }
}
class TextButton extends Button {  //テキストのみのボタン
  TextButton(int x, int y, float textSize, PFont font, String defaultValue, ButtonObserver origin) {  //defaultTextSize: フォントサイズ, defaultFont: フォント, defaultValue: 表示するテキスト, origin: このボタンを管理するインスタンス
    cx = x;  //各変数を設定
    cy = y;
    value = defaultValue;
    Text text = new Text(x, y, textSize, font, defaultValue);  //引数をもとにテキストコンポーネントを作成
    ch = text.ch;  //作成したテキストコンポーネントのサイズをこのコンポーネントのサイズに設定
    cw = text.cw;
    components.add(text);  //テキストコンポーネントをコンポーネントのリストに追加
    observer = origin;
  }
}
class BlackButton extends Button {  //黒いボタン
  BlackButton(int x, int y, int w, int h, String defaultValue, ButtonObserver origin) {  //defaultValue: 表示するテキスト, origin: このボタンを管理するインスタンス
    cx = x;  //各変数を設定
    cy = y;
    cw = w;
    ch = h;
    value = defaultValue;
    observer = origin;
  }

  void draw() {
    noStroke();  //背景を描画
    fill(18);
    rect(cx, cy, cw, ch, ch / 2);
    fill(255);  //テキストを描画
    textFont(NotoSans_m);
    textSize(18);
    textAlign(CENTER, CENTER);
    text(value, cx + cw / 2, cy + ch / 2);
  }
}
class WhiteButton extends Button {  //白いボタン
  WhiteButton(int x, int y, int w, int h, String defaultValue, ButtonObserver origin) {  //defaultValue: 表示するテキスト, origin: このボタンを管理するインスタンス
    cx = x;  //各変数を設定
    cy = y;
    cw = w;
    ch = h;
    value = defaultValue;
    observer = origin;
  }

  void draw() {
    stroke(18);  //枠線を描画
    strokeWeight(2);
    noFill();
    rect(cx, cy, cw, ch, ch / 2);
    fill(18);  //テキストを描画
    textFont(NotoSans_m);
    textSize(18);
    textAlign(CENTER, CENTER);
    text(value, cx + cw / 2, cy + ch / 2);
  }
}
interface ButtonObserver {  //ボタンを管理するクラスに実装するインターフェース
  void onclick(Button instance);  //管理するボタンが押されたときに呼び出される関数
}

class TextInput extends Component {  //テキスト入力欄のコンポーネント
  String value;  //入力されたテキスト
  boolean isSelected;  //この入力欄が選択済みかどうか
  TextInputObserver observer;  //テキスト入力欄を管理するインスタンスを参照
  int[] pointer = new int[2];  //カーソルの位置 0: primary, 1: secondary
  int pointerMoved;  //最後にカーソルが動いたミリ秒
  int shift;  //x方向のスクロール
  TextInput next;  //tabキーを押されたときに次に選択するテキスト入力欄のインスタンス

  TextInput(int x, int y, int w, int h, TextInputObserver origin, TextInput nextTextInput) {  //origin: この入力欄を管理するインスタンス, nextTextInput: 次に選択されるテキスト入力欄
    cx = x;  //各変数を設定
    cy = y;
    cw = w;
    ch = h;
    isSelected = false;
    observer = origin;
    shift = 0;
    next = nextTextInput;
  }

  void validatePointers() {  //カーソルの位置を文字列の範囲内にする関数
    for (int i = 0; i < pointer.length; ++i)
      pointer[i] = range(pointer[i], 0, value.length());
  }

  void draw() {
    validatePointers();  //カーソルの位置を正規化
    PImage capturedScreen = createImage(width, height, RGB);  //スクロールのはみ出し分を覆うために現在の画面をキャプチャ
    loadPixels();
    capturedScreen.pixels = pixels;
    for (int y = cy; y < cy + ch; ++y)  //キャプチャした画像からこのコンポーネントの部分を削除
      for (int x = cx; x < cx + cw; ++x)
        capturedScreen.pixels[y * width + x] = color(0, 0);
    fill(18);  //入力されたテキストを描画
    textFont(NotoSans_r);
    textSize(ch - 4);
    textAlign(LEFT, TOP);
    text(value, cx + shift, cy);
    while ((shift + textWidth(value.substring(0, pointer[0])) < 0) || (shift < 0 && ceil(shift + textWidth(value)) < cw))  //プライマリカーソルの位置に合わせてスクロール
      shift++;
    while (shift + textWidth(value.substring(0, pointer[0])) >= cw)
      shift--;
    if (isSelected) {
      if (pointer[0] == pointer[1]) {  //2つのカーソルが同じ位置にあるときのカーソルを描画
        if ((millis() - pointerMoved) % 1000 < 500) {  //0.5秒間隔で点滅
          stroke(18);  //カーソルを描画
          strokeWeight(1);
          float lx = cx + shift + textWidth(value.substring(0, pointer[0]));  //カーソルのx座標を計算
          line(lx, cy, lx, cy + ch - 4);
        }
      } else {  //2つのカーソルが異なる位置にあるときのカーソル(選択範囲)を描画
        int lPointer = min(pointer[0], pointer[1]);  //より左にあるカーソルの位置
        int rPointer = max(pointer[0], pointer[1]);  //より右にあるカーソルの位置
        float leftWidth = textWidth(value.substring(0, lPointer));  //選択範囲より左の文字列の幅
        String selected = value.substring(lPointer, rPointer);  //選択された文字列
        noStroke();  //選択範囲を黒で塗りつぶす
        rect(cx + shift + leftWidth, cy, textWidth(selected), ch - 4);
        fill(245);  //選択範囲のテキストを白で描画
        text(selected, cx + shift + leftWidth, cy);
      }
      strokeWeight(2);  //この入力欄が選択されているときには下線を太く
    } else
      strokeWeight(1);  //選択されていないときには細くする
    stroke(18);
    image(capturedScreen, 0, 0);  //スクロールによりはみ出した部分を削除
    line(cx, cy + ch, cx + cw, cy + ch);
  }

  void mouseClicked() {
    if (!isSelected) {  //新規選択時
      isSelected = true;  //選択状態を更新
      selectedTextInput = this;  //入力中のテキスト入力欄としてこのインスタンスを参照
      pointer[0] = value.length();  //文字列を全選択
      pointer[1] = 0;
      pointerMoved = millis();
    }
  }

  void mousePressed() {
    if (isSelected) {  //この入力欄が選択中のとき
      pointer[0] = pointer[1] = getPosition(mouseX - cx);  //クリックした位置にカーソルを移動
      pointerMoved = millis();
    }
  }

  void mouseDragged() {
    if (isSelected) {  //この入力欄が選択中のとき
      pointer[0] = getPosition(mouseX - cx);  //プライマリカーソルをマウスの位置に移動(文字を選択)
      pointerMoved = millis();
    }
  }
  
  void keyPressed() {
    validatePointers();  //カーソルの位置を正規化
    int lPointer = min(pointer[0], pointer[1]);  //より左にあるカーソルの位置
    int rPointer = max(pointer[0], pointer[1]);  //より右にあるカーソルの位置
    if (key == CODED) {  //keyTypedで呼び出されないキーが押下されていたとき
      switch (keyCode) {
        case 37:  //←
          if (pointer[0] == pointer[1]) {  //2つのカーソルの位置が同じときにはカーソルを1文字左にずらす
            if (pointer[0] > 0)
              pointer[0] = --pointer[1];
          } else  //2つのカーソルの位置が異なるとき、より左にあるカーソルの位置に統一
            pointer[0] = pointer[1] = lPointer;
          pointerMoved = millis();
          break;
        case 39:  //→
          if (pointer[0] == pointer[1]) {  //2つのカーソルの位置が同じときにはカーソルを1文字右にずらす
            if (pointer[0] < value.length())
              pointer[0] = ++pointer[1];
          } else  //2つのカーソルの位置が異なるとき、より右にあるカーソルの位置に統一
            pointer[0] = pointer[1] = rPointer;
          pointerMoved = millis();
          break;
      }
    }
  }

  void keyTyped() {
    validatePointers();  //カーソルの位置を正規化
    int lPointer = min(pointer[0], pointer[1]);  //より左にあるカーソルの位置
    int rPointer = max(pointer[0], pointer[1]);  //より右にあるカーソルの位置
    switch (int(key)) {
      case 1: //ctrl + a
        pointer[0] = value.length();  //テキストを全選択
        pointer[1] = 0;
        break;
      case 3: {  //ctrl + c
        StringSelection stringSelection;
        if (pointer[0] == pointer[1]) {  //2つのカーソルの位置が同じときには文字列すべてをクリップボードにコピー
          stringSelection = new StringSelection(value);
        } else {  //2つのカーソルの位置が異なるときには選択範囲をクリップボードにコピー
          stringSelection = new StringSelection(value.substring(lPointer, rPointer));
        }
        Toolkit.getDefaultToolkit().getSystemClipboard().setContents(stringSelection, stringSelection);
        break;
      }
      case 8:  //backspace
        if (pointer[0] == pointer[1]) {  //2つのカーソルの位置が同じときには1文字削除
          if (pointer[0] > 0) {
            value = value.substring(0, pointer[0] - 1) + value.substring(pointer[0], value.length());
            pointer[0] = --pointer[1];  //カーソルを移動
          }
        } else {  //2つのカーソルの位置が異なるときには選択範囲を削除
          value = value.substring(0, lPointer) + value.substring(rPointer, value.length());
          pointer[0] = pointer[1] = lPointer;  //カーソルを移動
          pointerMoved = millis();
        }
        break;
      case 9:  //tab
        blur();  //このテキスト入力欄の選択を解除
        if (next != null)  //次に選択されるテキスト入力欄が指定されていればそのテキスト入力欄を選択
          next.mouseClicked();
        break;
      case 10:  //enter
        blur();  //このテキスト入力欄の選択を解除
        break;
      case 22:  //ctrl + v
        try {
          String pastedText = String.valueOf(Toolkit.getDefaultToolkit().getSystemClipboard().getData(DataFlavor.stringFlavor)).replaceAll("\\p{C}", "");  //クリップボードからテキストを取得
          value = value.substring(0, lPointer) + pastedText + value.substring(rPointer, value.length());  //取得したテキストを入力中のテキストに挿入
          pointer[0] = pointer[1] = lPointer + pastedText.length();  //カーソルを移動
          pointerMoved = millis();
        } catch (UnsupportedFlavorException e) {
          //println(e);
        } catch (IOException e) {
          //println(e);
        }
        break;
      case 24: {  //ctrl + x
        StringSelection stringSelection;
        if (pointer[0] == pointer[1]) {  //2つのカーソルの位置が同じときには文字列すべてをクリップボードに切り取り
          stringSelection = new StringSelection(value);
          value = "";
          pointer[0] = pointer[1] = 0;  //カーソルを移動
        } else {  //2つのカーソルの位置が異なるときには選択範囲をクリップボードに切り取り
          stringSelection = new StringSelection(value.substring(lPointer, rPointer));
          value = value.substring(0, lPointer) + value.substring(rPointer, value.length());
          pointer[0] = pointer[1] = lPointer;  //カーソルを移動
          pointerMoved = millis();
        }
        Toolkit.getDefaultToolkit().getSystemClipboard().setContents(stringSelection, stringSelection);
        break;
      }
      case 127:  //delete
        if (pointer[0] == pointer[1]) {  //2つのカーソルの位置が同じときには1文字削除
          if (pointer[0] < value.length())
            value = value.substring(0, pointer[0]) + value.substring(pointer[0] + 1, value.length());
        } else {  //2つのカーソルの位置が異なるときには選択範囲を削除
          value = value.substring(0, lPointer) + value.substring(rPointer, value.length());
          pointer[0] = pointer[1] = lPointer;  //カーソルを移動
        }
        pointerMoved = millis();
        break;
      default:  //上記以外のキーが入力されたとき
        String typedText = String.valueOf(key).replaceAll("\\p{C}", "");  //制御文字を削除
        value = value.substring(0, lPointer) + typedText + value.substring(rPointer, value.length());  //入力中のテキストに挿入
        pointer[0] = pointer[1] = lPointer + typedText.length();  //カーソルを移動
      break;
    }
  }

  void onblur() {  //選択が解除されたときに呼び出される関数
    blur();  //選択を解除
  }

  void blur() {  //選択解除時の一連の処理を行う関数
    observer.onblur(this);  //このテキスト入力欄を管理するインスタンスに選択解除を伝達
    isSelected = false;  //選択状態を更新
    selectedTextInput = null;  //テキスト入力欄の参照を解除
  }

  int getPosition(int x) {  //引数xの座標が何文字目に相当するかを計算する関数
    int position = 0;
    while (position < value.length() && shift + textWidth(value.substring(0, ++position)) < x);  //x座標にある文字の次の文字を計算
    if (abs(shift + textWidth(value.substring(0, position - 1)) - x) < abs(shift + textWidth(value.substring(0, position)) - x))  //x座標にある文字の幅から最終的な文字数を計算
      position--;
    return position;  //文字数を返す
  }
}
interface TextInputObserver {  //テキスト入力欄を管理するクラスに実装するインターフェース
  void onblur(TextInput instance);  //テキスト入力欄の選択が解除されたときに呼び出される関数
}

class Tab extends Component {  //ページ内で切り替わるタブに相当するクラス
  String title;  //タブのタイトル

  Tab(String defaultTitle) {  //タブの領域はタブグループの領域に依存 defaultTitle: タブのタイトルの初期値
    cx = 0;  //各変数を設定
    cy = 0;
    cw = width;
    ch = height;
    title = defaultTitle;
  }
}

class TabSelector extends Component {  //タブを切り替えるUIコンポーネント
  TabGroup tabGroup;  //タブグループを保持

  TabSelector(int x, int y, int w, int h, TabGroup defaultTabGroup) {  //defaultTabGroup: 扱うタブグループの初期値
    cx = x;  //各変数を設定
    cy = y;
    cw = w;
    ch = h;
    tabGroup = defaultTabGroup;
    tabGroup.changeTab(0);  //0番目のタブに切り替える
  }

  void draw() {
    stroke(163);  //全体の下線を描画
    strokeWeight(1);
    line(cx, cy + ch, cx + cw, cy + ch);
    textFont(NotoSans_m);
    textSize(ch - 12);
    textAlign(LEFT, TOP);
    strokeWeight(2);
    int shift = 0;
    for (int i = 0; i < tabGroup.tabs.size(); ++i) {  //各タブのタイトルを描画する
      float tabWidth = textWidth(tabGroup.tabs.get(i).title);
      if (tabGroup.selected == i) {
        stroke(18);  //選択中のタブの下線を描画
        line(cx + shift, cy + ch, cx + shift + tabWidth, cy + ch);
        fill(18);  //選択中のタブのタイトルのみ黒で描画
      }
      else fill(163);  //選択中でないタブのタイトルはグレーで描画
      text(tabGroup.tabs.get(i).title, cx + shift, cy);
      shift += tabWidth + 18;  //描画したタイトルの分次のタイトルをずらす
    }
  }

  void mouseClicked() {  //クリックされたら
    int shift = 0;
    for (int i = 0; i < tabGroup.tabs.size(); ++i) {  //マウスの位置からクリックしたタブを逆算
      float tabWidth = textWidth(tabGroup.tabs.get(i).title);
      if (tabGroup.selected != i && isOver(cx + shift, cy, tabWidth, ch, mouseX, mouseY, 0, 0)) {
        tabGroup.changeTab(i);  //該当するタブがあればそのタブに切り替え
      }
      shift += tabWidth + 18;
    }
  }
}

class TabGroup extends Component {  //タブセレクタで選択できるタブのグループに相当するクラス
  ArrayList<Tab> tabs = new ArrayList<Tab>();  //タブを保持
  int selected;  //現在のタブ

  TabGroup(int x, int y, int w, int h) {  //このコンポーネントの領域がタブの操作領域になる
    cx = x;  //各変数を設定
    cy = y;
    cw = w;
    ch = h;
    selected = 0;
  }

  void changeTab(int to) {  //タブを変更する関数
    components.clear();  //コンポーネントに保持するタブを切り替え
    components.add(tabs.get(to));
    selected = to;  //現在のタブを変更
  }
}

class Dialog extends Component {  //ダイアログに共通するクラス
  DialogObserver observer;  //ダイアログを管理するインスタンスを参照
  int bx, by, bw, bh;  //ダイアログボックスの位置と大きさ

  void draw() {
    noStroke();  //背景を描画
    fill(0, 128);
    rect(cx, cy, cw, ch);
    fill(255);  //ダイアログの背景を描画
    rect(bx, by, bw, bh, 12);
    drawComponents();  //ダイアログの内容を描画
  }

  void close() {  //ダイアログを閉じるときに呼び出される関数
    observer.onclose(this);  //このダイアログを管理するインスタンスに選択解除を伝達
  }
}
interface DialogObserver {  //ダイアログを管理するクラスに実装するインターフェース
  void onclose(Dialog instance);  //ダイアログが閉じられたときに呼び出される関数
}

class ScrollBox extends Component {  //スクロールできるコンポーネントに共通のクラス
  int scrollY;  //スクロール位置

  void draw() {
    PImage capturedScreen = createImage(width, height, RGB);  //スクロールのはみ出し分を覆うために現在の画面をキャプチャ
    loadPixels();
    capturedScreen.pixels = pixels;
    for (int y = cy; y < cy + ch; ++y)  //キャプチャした画像からこのコンポーネントの部分を削除
      for (int x = cx; x < cx + cw; ++x)
        capturedScreen.pixels[y * width + x] = color(0, 0);
    drawComponents();  //子コンポーネントを描画
    image(capturedScreen, 0, 0);  //スクロールによりはみ出した部分を削除
  }

  void mouseWheel(MouseEvent event) {  //スクロールされたら
    int bottom = 0;
    for (int i = 0; i < components.size(); ++i)  //コンポーネントの最下点を計算
      bottom = max(components.get(i).cy + scrollY - cy + components.get(i).ch - ch, bottom);
    int targetY = range(scrollY + event.getCount() * 16, 0, bottom);  //目標のスクロール位置
    int offsetY = targetY - scrollY;  //現在のスクロール位置との差分
    for (int i = 0; i < components.size(); ++i)  //コンポーネントにスクロールを反映
      components.get(i).cy -= offsetY;
    scrollY = targetY;  //スクロール位置を更新
  }
}

class Loading extends Component {  //ローディング画面のコンポーネント
  float progress;  //0-100の進行度

  Loading() {
    cx = 0;  //各変数を設定
    cy = 0;
    cw = width;
    ch = height;
    progress = 0;  //進行度を初期化
  }

  void draw() {
    noStroke();  //背景を描画
    fill(0, 128);
    rect(cx, cy, cw, ch);
    fill(255);
    strokeWeight(4);  //枠線を描画
    rect(132, 354, 216 * progress / 100, 12);
    noFill();  //進行度を描画
    stroke(255);
    rect(126, 348, 228, 24);
  }
}
