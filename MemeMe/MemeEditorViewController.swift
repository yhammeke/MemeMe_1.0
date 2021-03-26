//
//  ViewController.swift
//  MemeMe
//
//  Created by Yuriy Hammeke on 23.03.21.
//

import UIKit

class ViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate, UITextFieldDelegate {
    
    //MARK: Properties

    @IBOutlet weak var toolBar: UIToolbar!
    @IBOutlet weak var imagePickerView: UIImageView!
    @IBOutlet weak var cameraButton: UIBarButtonItem!
    
    @IBOutlet weak var navBar: UIToolbar!
    @IBOutlet weak var shareButton: UIBarButtonItem!
    @IBOutlet weak var cancelButton: UIBarButtonItem!
    
    @IBOutlet weak var topTextField: UITextField!
    @IBOutlet weak var bottomTextField: UITextField!
    
    var keyboardAppearCounter: Int = 0
    
    
    let memeTextAttributes: [NSAttributedString.Key: Any] = [
        NSAttributedString.Key.strokeColor: UIColor.black,
        NSAttributedString.Key.foregroundColor: UIColor.white,
        NSAttributedString.Key.font: UIFont(name: "HelveticaNeue-CondensedBlack", size: 40)!,
        NSAttributedString.Key.strokeWidth: -3.0
    ]
    
    // MARK: APP Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        self.topTextField.defaultTextAttributes = memeTextAttributes
        self.topTextField.text = "TOP"
        self.topTextField.textAlignment = .center
        
        self.bottomTextField.defaultTextAttributes = memeTextAttributes
        self.bottomTextField.text = "BOTTOM"
        self.bottomTextField.textAlignment = .center
        
        self.topTextField.delegate = self
        self.bottomTextField.delegate = self
        
        self.shareButton.isEnabled = false
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        cameraButton.isEnabled = UIImagePickerController.isSourceTypeAvailable(.camera)
        
        super.viewWillAppear(animated)
        subscribeToKeyboardNotifications()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        unsubscribeFromKeyboardNotifications()
    }
    
    // MARK: View Controller Functions
    
    @IBAction func pickAnImageFromAlbum(_ sender: Any) {
        let imagePicker = UIImagePickerController()
        imagePicker.delegate = self
        imagePicker.sourceType = .photoLibrary
        present(imagePicker, animated: true, completion: nil)
    }
    
    @IBAction func pickAnImageFromCamera(_ sender: Any) {
        let imagePicker = UIImagePickerController()
        imagePicker.delegate = self
        imagePicker.sourceType = .camera
        present(imagePicker, animated: true, completion: nil)
    }
    
    // MARK: MemeObject Function
    
    // Generate the Memed Picture
    func generateMemedImage() -> UIImage {
        
        navBar.isHidden = true
        toolBar.isHidden = true
        
        // Render view to an image
        UIGraphicsBeginImageContext(self.view.frame.size)
        view.drawHierarchy(in: self.view.frame, afterScreenUpdates: true)
        let memedImage:UIImage = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        
        navBar.isHidden = false
        toolBar.isHidden = false
        
        return memedImage
    }
    
    // Save the Meme function
    func save() {
        
        // Update the meme
        let meme = Meme(topText: topTextField.text, bottomText: bottomTextField.text, origImage: imagePickerView.image!, memedImage: generateMemedImage())
        
        // Add the Meme to the array of Memes on the Application Delegate
        //(UIApplication.shared.delegate as! AppDelegate).memes.append(meme)
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        appDelegate.memes.append(meme)
        
        dismiss(animated: true, completion: nil)
    }
    
    // MARK: Keyboard notification Subsription Functions
    
    func subscribeToKeyboardNotifications() {
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow(_:)), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide(_:)), name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    func unsubscribeFromKeyboardNotifications() {
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    @objc func keyboardWillShow(_ notification: Notification) {
        keyboardAppearCounter += 1
        if keyboardAppearCounter < 2 { // Avoid the double-call of the function.
            if self.topTextField.text != "" { // Avoid the view adaptation for top string
                view.frame.origin.y -= getKeyboardHeight(notification)
                print(view.frame.origin.y)
            }
        }
    }
    
    @objc func keyboardWillHide(_ notification: Notification) {
        keyboardAppearCounter = 0
        view.frame.origin.y = 0
    }
    
    func getKeyboardHeight(_ notification: Notification) -> CGFloat {
        let userInfo = notification.userInfo
        let keyboardSize = userInfo![UIResponder.keyboardFrameEndUserInfoKey] as! NSValue
        return keyboardSize.cgRectValue.height
    }
    
    // MARK: TextField Delegate Functions
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        //self.topTextField.text = ""
        //textField.text = ""
        switch textField {
        case topTextField:
            topTextField.text = ""
        case bottomTextField:
            bottomTextField.text = ""
        default:
            break
        }
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        
        if textField.text == "" {
            switch textField {
            case topTextField:
                textField.text = "TOP"
            case bottomTextField:
                textField.text = "BOTTOM"
            default:
                break
            }
        }
        return true
    }
    
    
    // MARK: imagePicker Delegate Functions
    
    func imagePickerController(_ picker: UIImagePickerController,
                               didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let image = info[UIImagePickerController.InfoKey.originalImage] as? UIImage {
            imagePickerView.image = image
        }
        
        // Close the Image Picker after the successful Image selection.
        dismiss(animated: true, completion: nil)
        
        self.shareButton.isEnabled = true
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        // Close the Image Picker if Cancel button was clicked.
        dismiss(animated: true, completion: nil)
    }
    
    // MARK: SHARE action method
    
    @IBAction func shareMeme(_ sender: Any) {
        let memeToBeShared = generateMemedImage()
        
        let activityViewController = UIActivityViewController(activityItems: [memeToBeShared], applicationActivities: nil)
        
        activityViewController.completionWithItemsHandler = {activity, success, items, error in
            if success {
                self.save()
            }
        }
        
        present(activityViewController, animated: true, completion: nil)
    }
    

}
