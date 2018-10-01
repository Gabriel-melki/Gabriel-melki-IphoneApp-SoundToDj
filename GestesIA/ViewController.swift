//
//  ViewController.swift
//  GestesIA
//
//  Created by Gaspard de Veyrac on 16/02/2018.
//  Copyright © 2018 Gaspard de Veyrac. All rights reserved.
//

import UIKit
import CoreMotion
import CocoaAsyncSocket
import Swift

class ViewController: UIViewController , UITextFieldDelegate {
    //Déclaration des composants de l'app
    @IBOutlet weak var valueLabel: UILabel!
    @IBOutlet weak var addressIP: UITextField!
    @IBOutlet weak var portField: UITextField!
    @IBOutlet weak var accelTagX: UILabel!
    @IBOutlet weak var gyrosTagX: UILabel!
    @IBOutlet weak var connect: UIButton!
    @IBOutlet weak var accelTagY: UILabel!
    @IBOutlet weak var gyrosTagY: UILabel!
    @IBOutlet weak var stepper: UIStepper!
    @IBOutlet weak var accelTagZ: UILabel!
    @IBOutlet weak var gyrosTagZ: UILabel!
    //Le bouton Connect qui se sert des champs addressIP et portField
    @IBAction func startConnection(_ sender: Any) {
            outSocket = OutSocket()
            outSocket.param(addressIP:String(describing: addressIP.text!),
                            portField:UInt16(Int(portField.text!)!))
            outSocket.setupConnection()
            startAccelerometer(outSocket)
            startGyros(outSocket)
    }
    //Parametrer le pas de temps
    @IBAction func stepperValueChanged(_ sender: UIStepper) {
        valueLabel.text = Int(sender.value).description
        speed = sender.value
    }

    var motionManager = CMMotionManager()
    var speed: Double = 0.0
    var outSocket : OutSocket!

    
    override func viewDidLoad() {
        UIApplication.shared.isIdleTimerDisabled = true
        super.viewDidLoad()
        valueLabel.text = "1"
        speed = 1
        self.addressIP.delegate = self
        self.portField.delegate = self
        addressIP.text = "192.168.153.209"
        portField.text = "52786"
        stepper.wraps = false
        stepper.maximumValue = 10
        stepper.minimumValue = 1
       
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.view.endEditing(true)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
//Classe pour récupérer les données gyroscope
    func startGyros (_ outSocket: OutSocket) {
        motionManager.gyroUpdateInterval = 1/(2*speed)
        motionManager.startGyroUpdates(to: OperationQueue.current!, withHandler: {
            (gyroData:CMGyroData?, error: Error?) in
            if (error != nil ) {
                print("Error")
            } else {
                let gyroX = gyroData?.rotationRate.x
                let gyroY = gyroData?.rotationRate.y
                let gyroZ = gyroData?.rotationRate.z
                self.gyrosTagX.text = String(format: "%.02f", gyroX!)
                self.gyrosTagY.text = String(format: "%.02f", gyroY!)
                self.gyrosTagZ.text = String(format: "%.02f", gyroZ!)
                outSocket.send(message: "1.0 \(gyroX!) \(gyroY!) \(gyroZ!)")
                print("Gyroscope : \(gyroX!) \(gyroY!) \(gyroZ!)")
            }
        })
    }

//Classe pour récupérer les données accélorometre
    func startAccelerometer (_ outSocket: OutSocket) {
        motionManager.accelerometerUpdateInterval = 1/(2*speed)
        motionManager.startAccelerometerUpdates(to: OperationQueue.current!, withHandler: {
            (accelerData:CMAccelerometerData?, error: Error?) in
            if (error != nil ) {
                print("Error")
            } else {
                let accelX = accelerData?.acceleration.x
                let accelY = accelerData?.acceleration.y
                let accelZ = accelerData?.acceleration.z
                self.accelTagX.text = String(format: "%.02f", accelX!)
                self.accelTagY.text = String(format: "%.02f", accelY!)
                self.accelTagZ.text = String(format: "%.02f", accelZ!)
                outSocket.send(message: "2.0 \(accelX!) \(accelY!) \(accelZ!)")
                print("Accelerometer : \(accelX!) \(accelY!) \(accelZ!)")
            }
        })
    }
    
    func textFieldShouldClear(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    
    
}

//la classe qui permet d'envoyer les données grace à UDP.
class OutSocket: NSObject, GCDAsyncUdpSocketDelegate {
    
    var IP:String!
    var PORT:UInt16!
    var socket:GCDAsyncUdpSocket!
    
    override init(){
        super.init()
    }
    
    func param(addressIP:String,portField:UInt16){
        IP = addressIP
        PORT = portField
    }
    
    
    func setupConnection(){
        socket = GCDAsyncUdpSocket(delegate: self, delegateQueue: DispatchQueue.main)
        try? socket.bind(toPort: PORT)
        try? socket.connect(toHost: IP, onPort: PORT)
        try? socket.beginReceiving()
        print("message envoyé")
        send(message: "ping")
    }
    
    func send(message:String){
        let data = message.data(using: String.Encoding.utf8)
        socket.send(data!, withTimeout: 2, tag: 0)
    }
    
}


