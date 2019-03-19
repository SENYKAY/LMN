//
//  ViewController.swift
//  LoseMeNot
//
//  Created by Horseman on 06/12/2018.
//  Copyright © 2018 ITSln. All rights reserved.
//

import UIKit
import CoreLocation

class ViewController: UIViewController  {
    
    private lazy var locationManager: CLLocationManager = {
        let manager = CLLocationManager()
        manager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters //kCLLocationAccuracyBestForNavigation
        manager.requestAlwaysAuthorization()
        manager.delegate = self
        manager.allowsBackgroundLocationUpdates = true
        manager.pausesLocationUpdatesAutomatically = false
        return manager
    }()
    
    let sounds = SoundCollection()
    let observer = MainObserver()
    
    @IBOutlet weak var pickerSounds: UIPickerView!
    @IBOutlet weak var pickerTimer: UIPickerView!
    @IBOutlet weak var buttonPay: UIButton!
    
    // кнопка поделиться
    let shareLink = "https://www.facebook.com/Lose-Me-Not-277036296305496/"
    @IBAction func share(_ sender: Any) {
        let shareVC = UIActivityViewController(activityItems: [shareLink], applicationActivities: nil)
        shareVC.popoverPresentationController?.sourceView = self.view
        
        self.present(shareVC, animated: true, completion: nil)
    }
    
    // кнопка лайкнуть
    let url = URL(string: "itms://itunes.apple.com/app/id1450725018")!
    @IBAction func like(_ sender: Any) {        
        if #available(iOS 10.0, *) {
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        } else {
            UIApplication.shared.openURL(url)
        }
    }
    
    // кнопка купить
    @IBAction func buy(_ sender: Any) {
        buy()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        checkPermissions()
        initPickers()
        
        checkPayment()
        // стартуем
        start()
    }
    
    private func checkPermissions() {
        //есть тут проблемы с асинхроностью при проверке доступа к микрофону...
        observer.session.requestRecordPermission() { [unowned self] allowed in
            self.observer.setPermissions(allowed)
        }
    }
    
    private func subscribed() {
        // если куплено, то не нужна кнопка
        self.buttonPay.isHidden = true
        // открываем опции
        self.pickerTimer.isUserInteractionEnabled = true
        self.pickerSounds.isUserInteractionEnabled = true
    }
    
    private func checkPayment() {
        // обратимся в магазин
        LmnProducts.store.load { [weak self] success in
            guard let self = self else { return }
            // не смогли проверить подписку
            guard success else {
                self.alert(title: "Failed to check subscription", message: "No App Store connection. Try to start later")
                return
            }
            // проверим подписку
            if LmnProducts.store.checkMonthly() {
                self.subscribed()
            }
            else {
                // ограничиваем выбор
                self.pickerTimer.isUserInteractionEnabled = false
                self.pickerSounds.isUserInteractionEnabled = false
            }
        }
    }

//    let alertController = UIAlertController(title: "Необходимо подтвердить покупку",
//                                            message: "Привет! Наше приложение платное, но у вас есть пробный месяц, чтобы оценить его по достоинству и осознанно перейти к оплате всего 1$ в месяц.",
//                                            preferredStyle: .alert)
//    alertController.addAction(UIAlertAction(title: "Подтвердить", style: .default) { _ in self.buy() })
//    alertController.addAction(UIAlertAction(title: "Отказаться", style: .default) { _ in
//    self.alert(title: "Оплата не произведена", message: "Сожалеем, основной функционал приложения отключен.") })
//    self.present(alertController, animated: true, completion: nil)

    
    
    private func buy() {
        LmnProducts.store.buy { success in
            if success {
                self.alert(title: "Оплата произведена", message: "Поздравляем с удачным приобретением!")
                self.subscribed()
            } else {
                self.alert(title: "Оплата не произведена", message: "Сожалеем, основной функционал приложения отключен.")
            }
        }
    }
    
    private func alert(title: String, message: String) {
        let alertController = UIAlertController(title: title,
                                                message: message,
                                                preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "OK", style: .default))
        self.present(alertController, animated: true, completion: nil)
    }
    
    private func start() {
        // начинаем с auto-режима
        observer.start()
        
        // запускаем проверку состояния
        locationManager.startUpdatingLocation()
    }
    
    let delays = [60, 45, 30, 15, 5, 1]
    let defaultDelayIdx = 4 // 5 минут
    
    // справочники
    private func initPickers() {
        pickerSounds.dataSource = self
        pickerSounds.delegate = self
        pickerTimer.selectRow(0, inComponent: 0, animated: false)
        let snd = sounds.getFileName(0)
        observer.player.setSound(snd)
        
        pickerTimer.dataSource = self
        pickerTimer.delegate = self
        pickerTimer.selectRow(defaultDelayIdx, inComponent: 0, animated: false)
        self.pickerView(pickerTimer, didSelectRow: defaultDelayIdx, inComponent: 0)
    }
}

// MARK: - CLLocationManagerDelegate
extension ViewController: CLLocationManagerDelegate {
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let _:CLLocation = locations[0] as CLLocation
        
        print("CLLocationManagerDelegate: \(Date())")

        observer.check()
    }
    
}

// MARK: - UIPickerViewDelegate
extension ViewController: UIPickerViewDelegate, UIPickerViewDataSource {
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        // для обоих один компонент
        return 1
    }
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        switch pickerView {
        case pickerSounds:
            return sounds.getCount()
        case pickerTimer:
            return delays.count
        default:
            return 1
        }
    }
    func pickerView(_ pickerView: UIPickerView, viewForRow row: Int, forComponent component: Int, reusing view: UIView?) -> UIView {
        var pickerLabel: UILabel?  = (view as? UILabel)
        if pickerLabel == nil {
            pickerLabel = UILabel()
            
            if UIDevice.current.userInterfaceIdiom == .pad {
                pickerLabel!.font = UIFont.systemFont(ofSize: 30)
            } else if UIDevice.current.userInterfaceIdiom == .phone {
                pickerLabel!.font = UIFont.systemFont(ofSize: 18)
            }
        }
        switch pickerView {
        case pickerSounds:
            pickerLabel!.text = sounds.getName(row)
            pickerLabel!.textColor = UIColor.init(named: "MainColor") ?? UIColor.black
            pickerLabel!.textAlignment = .right
        case pickerTimer:
            pickerLabel!.text = "\(delays[row]) m."
            pickerLabel!.textColor = UIColor.white
        default:
            pickerLabel!.text = ""
        }
        return pickerLabel!
    }
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        switch pickerView {
        case pickerSounds:
            let sound = sounds.getFileName(row)
            observer.setSound(sound)
            break
        case pickerTimer:
            let delay = delays[row]
            observer.setDelay(delay)
        default:
            return
        }
    }
}

