//
//  ProfileViewController.swift
//  CareEsteem
//
//  Created by Gaurav Gudaliya on 13/03/25.
//

import UIKit
import UserNotifications

class ProfileViewController: UIViewController {

    @IBOutlet weak var lblName: UILabel!
    @IBOutlet weak var lblAgency: UILabel!
    @IBOutlet weak var lblAge: UILabel!
    @IBOutlet weak var lblContactNumber: UILabel!
    @IBOutlet weak var lblEmail: UILabel!
    @IBOutlet weak var lblAddress: UILabel!
    @IBOutlet weak var lblCity: UILabel!
    @IBOutlet weak var lblPostCode: UILabel!
 
    @IBOutlet weak var profileSwitch: UISwitch!
    @IBOutlet weak var lblVersion: UILabel!
    @IBOutlet weak var btnLogout: AGButton!
    
    @IBOutlet weak var notificationSwitch: UISwitch!
    @IBOutlet weak var imgProfile: AGImageView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationController?.interactivePopGestureRecognizer?.isEnabled = false
        self.setupData()
        self.getProfile_APICall()
        self.btnLogout.action = {
            let vc = Storyboard.Main.instantiateViewController(withViewClass: PopupLogoutViewController.self)
            vc.confirmHandler = {
                UserDetails.shared.loginModel = nil
                UserDefaults.standard.removeObject(forKey: "loginModel")
                let vc = Storyboard.Login.instantiateViewController(withViewClass: LoginViewController.self)
                let navi = CustomNavigationController(rootViewController: vc)
                navi.isNavigationBarHidden = true
                AppDelegate.shared.window?.rootViewController = navi
            }
            vc.transitioningDelegate = customTransitioningDelegate
            vc.modalPresentationStyle = .custom
            self.present(vc, animated: true)
        }
        self.lblVersion.text = "Version "+Application.appVersion+"(\(Application.appBuild))"
    }
    
    private func displayValue(_ value: String?) -> String {
        if let trimmed = value?.trimmingCharacters(in: .whitespacesAndNewlines), !trimmed.isEmpty {
            return trimmed
        }
        return "N/A"
    }
    func setupData() {
        self.getNotoficationList_APICall()
        if let profile = UserDetails.shared.profileModel{
            if let profile = UserDetails.shared.profileModel {
                self.lblName.text = displayValue(profile.name)
                self.lblAgency.text = displayValue(profile.agency)
                
                if let age = profile.age, age > 0 {
                    self.lblAge.text = "\(age)"
                } else {
                    self.lblAge.text = "N/A"
                }
                
                self.lblContactNumber.text = displayValue(profile.contactNumber)
                self.lblEmail.text = displayValue(profile.email)
                print("profile email :- ", profile.email ?? "N/A")
                self.lblAddress.text = displayValue(profile.address)
                self.lblCity.text = displayValue(profile.city)
                self.lblPostCode.text = displayValue(profile.postcode)
                self.imgProfile.image = profile.profilePhoto?.base64ToUIImage() ?? UIImage(named: "logo_app")
            } else {
                self.lblName.text = "N/A"
                self.lblAgency.text = "N/A"
                self.lblAge.text = "N/A"
                self.lblContactNumber.text = "N/A"
                self.lblEmail.text = "N/A"
                self.lblAddress.text = "N/A"
                self.lblCity.text = "N/A"
                self.lblPostCode.text = "N/A"
            }
        }
            profileSwitch.isUserInteractionEnabled = true
        notificationSwitch.isEnabled = false
            
            
            if UserDefaults.standard.bool(forKey: "isfaceIDOn"){
                profileSwitch.setOn(true, animated: true)
            }else{
                profileSwitch.setOn(false, animated: true)
            }
            
            hasNotificationPermission(completion: { status in
                DispatchQueue.main.async {[weak self] in
                    self?.notificationSwitch.setOn(status, animated: true)
                }
            })
        }
    
    @IBAction func toggle(_ sender: UISwitch) {
        UserDefaults.standard.set(sender.isOn, forKey: "isfaceIDOn")
        UserDefaults.standard.synchronize()
        let message = sender.isOn ? "Face ID enabled" : "Face ID disabled"
        
        var style = ToastStyle()
        style.backgroundColor = UIColor(named: "appGreen") ?? .green
        AppDelegate.shared.window?.makeToast(message, style: style)
        
    }
    
    private func hasNotificationPermission(completion: @escaping (Bool) -> Void) {
        UNUserNotificationCenter.current().getNotificationSettings { (settings) in
            completion(settings.authorizationStatus == .authorized)
        }
    }
    
    @IBAction func btnSwitchAccount(_ sender : UIButton){
       // AppDelegate.shared.logOut()
        
        let vc = Storyboard.Main.instantiateViewController(withViewClass: CommonPopupViewController.self)
        vc.strImage = "switch"
        vc.strTitle = "You are about to switch accounts."
        vc.strButton = "Switch Account"
        vc.strCancelButton = "Cancel"
        vc.strMessage = "Unsaved changes or data in your current session may to lost. \nDo you want to continue?"
        vc.buttonClickHandler = {
            AppDelegate.shared.logOut()
          //  self.updateVisitCheckinTime_APICall()
        }
        vc.transitioningDelegate = customTransitioningDelegate
        vc.modalPresentationStyle = .custom
        self.present(vc, animated: true)
    }


    func showAlert() {
            let alert = UIAlertController(title: "Alert", message: stepRecordText, preferredStyle: .alert)
            
            // Copy action
            let copyAction = UIAlertAction(title: "Copy", style: .default) { _ in
                UIPasteboard.general.string = stepRecordText
                print("Text copied to clipboard")
            }
            
            // Cancel action
            let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
            
            alert.addAction(copyAction)
            alert.addAction(cancelAction)
            
            present(alert, animated: true)
        }

}
// MARK: API Call
extension ProfileViewController {
    
    private func getProfile_APICall() {
        
        WebServiceManager.sharedInstance.callAPI(apiPath: .getAllUsers(userId: UserDetails.shared.user_id), method: .get, params: [:],isAuthenticate: true, model: CommonRespons<[ProfileModel]>.self) { response, successMsg in
            switch response {
            case .success(let data):
                DispatchQueue.main.async {[weak self] in
                    if data.statusCode == 200{
                        UserDetails.shared.profileModel = data.data?.first
                        self?.setupData()
                        
                    }else{
                        self?.view.makeToast(data.message ?? "")
                    }
                }
            case .failure(let error):
                DispatchQueue.main.async {[weak self] in
                    self?.view.makeToast(error.localizedDescription)
                }
            }
        }
    }
    private func getNotoficationList_APICall() {
            
           // CustomLoader.shared.showLoader(on: self.view)
            WebServiceManager.sharedInstance.callAPI(apiPath: .getallnotifications(userId: UserDetails.shared.user_id), method: .get, params: [:],isAuthenticate: true, model: CommonRespons<[NotificationModel]>.self) { response, successMsg in
              //  CustomLoader.shared.hideLoader()
                switch response {
                case .success(let data):
                    DispatchQueue.main.async {
                        if data.statusCode == 200{
                            let array = data.data ?? []
                            notificationCount = array.count
                            print("Ayushi :- ",notificationCount)
                               // You can include an optional userInfo dictionary to pass data
                            NotificationCenter.default.post(name: .customNotification,
                                                            object: nil,
                                                            userInfo: ["message": "Data from the sender!",
                                                                       "count": array.count])
                           
                          

                        } else {
                            print("Error Code :-",data.statusCode)
                           
                        }
                    }

                case .failure(_):
                    print("no code")
                }
            }
        }
}


