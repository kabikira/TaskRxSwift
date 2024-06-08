//
//  File.swift
//  TaskRxSwift
//
//  Created by sakiyamaK on 2020/05/30.
//  Copyright © 2020 sakiyamaK. All rights reserved.
//

/*
 RxCocoaの機能を使う
 */
import UIKit
import RxSwift
import RxCocoa
import RxGesture
import NSObject_Rx

final class Task4ViewController: UIViewController, HasDisposeBag/*NSObject_Rxを使う*/ {

  //HasDisposeBagに準拠してるといらなくなる
  //  private let disposeBag = DisposeBag()

  @IBOutlet private weak var view1: UIView!
  @IBOutlet private weak var button1: UIButton!
  @IBOutlet private weak var textField1: UITextField!

  @IBOutlet private weak var view2: UIView!
  @IBOutlet private weak var button2: UIButton!
  @IBOutlet private weak var textField2: UITextField!

  override func viewDidLoad() {
    super.viewDidLoad()
//    example1()
//    example2()
      test()
  }

  private func example1() {
    do {
      //view1のタップ RxGestureを使う
      view1.rx.tapGesture().when(.recognized).subscribe(onNext: { (_) in
        debugPrint("view1 tapped")
      }).disposed(by: disposeBag)
    }
    do {
      button1.rx.tap.subscribe(onNext: { (_) in
        debugPrint("button1 tapped")
      }).disposed(by: disposeBag)
    }
    do {
      textField1.rx.controlEvent(.editingChanged).subscribe(onNext: { (_) in
        debugPrint("textField1 .editingChanged")
      }).disposed(by: disposeBag)
    }
  }

  private func example2() {
    //textField2の値が変わる度に流れるストリーム
    let changeTextFieldObservable = textField2.rx.controlEvent(.editingChanged)
      .map {[weak self] _ -> UIColor in //mapで流れるイベントをUIColorに変換
        guard let text = self?.textField2.text else { return UIColor.black }
        //textfieldのテキストに合わせてUIColorを生成してイベントとする
        var white = CGFloat(Double(text) ?? 0.0)
        white = min(1.0, max(0.0, white/255)) //0~1の間になる
        let color = UIColor.init(white: white, alpha: 1.0)
        return color
    }

    //button2をタップしたときのストリーム
    let tapButtonObservable = button2.rx.tap
      .subscribeOn(MainScheduler.instance) //メインスレッドで処理(このあとviewを更新するから
      .do(onNext: {[weak self] (_) in //イベントがきたらtextField2を初期化する
        self?.textField2.text = ""
      }).map {_ in // mapで返す値をUIColor.blackに変換
        UIColor.black
    }

    //ふたつのストリームをマージ
    let changeColorObservable = Observable.merge(
      tapButtonObservable,
      changeTextFieldObservable
    )

    //changeColorObservableのイベントを購買してview2.rx.backgroundColor渡す
    changeColorObservable.subscribeOn(MainScheduler.instance).subscribe(onNext: {[weak self] (color) in
      self?.view2.backgroundColor = color
    }).disposed(by: disposeBag)
    //イベントの値を直接渡す場合はbindでこう渡した方が直感的
//    changeColorObservable.subscribeOn(MainScheduler.instance).bind(to: view2.rx.backgroundColor).disposed(by: disposeBag)
  }



  @IBOutlet private weak var redTextField: UITextField!
  @IBOutlet private weak var greenTextField: UITextField!
  @IBOutlet private weak var blueTextField: UITextField!
  @IBOutlet private weak var view3: UIView!

    private func test() {
        //問1
        //redTextField, greenTextField, blueTextField
        //３つのテキストフィールドの値が変わったらイベントを流して
        //view3のbackgroundColorの色を変える
        let redObservable = redTextField.rx.text.orEmpty
            .map { text -> CGFloat in
                let value = CGFloat((text as NSString).floatValue)
                return min(1.0, max(0.0, value / 255.0))
            }

        let greenObservable = greenTextField.rx.text.orEmpty
            .map { text -> CGFloat in
                let value = CGFloat((text as NSString).floatValue)
                return min(1.0, max(0.0, value / 255.0))
            }

        let blueObservable = blueTextField.rx.text.orEmpty
            .map { text -> CGFloat in
                let value = CGFloat((text as NSString).floatValue)
                return min(1.0, max(0.0, value / 255.0))
            }

        Observable.combineLatest(redObservable, greenObservable, blueObservable)
            .map { (red, green, blue) -> UIColor in
                return UIColor(red: red, green: green, blue: blue, alpha: 1.0)
            }
            .subscribe(onNext: { [weak self] color in
                self?.view3.backgroundColor = color
            })
            .disposed(by: disposeBag)
  }
}
