//
//  PreviewViewController.swift
//  CustomCamera
//
//  Created by Tankar Shah on 23/09/19.
//  Copyright © 2019 Tankar Shah. All rights reserved.
//

import UIKit


class PreviewViewController: UIViewController,UIScrollViewDelegate {
    
    //MARK:- Param
    var img: UIImage!
    
    //MARK:- IBOutlet
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var navigationBarHeightConst: NSLayoutConstraint!
    
    //MARK:- View Life Cycle Methods
    override func viewDidLoad() {
        super.viewDidLoad()
        self.imageView.image = self.img
        self.scrollView.minimumZoomScale = 1.0
        self.scrollView.maximumZoomScale = 10.0
        self.scrollView.scrollsToTop = false
        
        if self.deviceIsiPhoneX(){
            self.navigationBarHeightConst.constant = 85
        } else {
            self.navigationBarHeightConst.constant = 65
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
    }
    
    /** FUNCTION COMMENT
     Use : to check device is of iPhoneX family
     From where it is called : called from child class by overriding it
     Arguments : nil
     Return Type : Bool
     **/
    func deviceIsiPhoneX() -> Bool {
        if UIDevice().userInterfaceIdiom == .phone {
            let height : CGFloat =  UIScreen.main.nativeBounds.size.height
            switch height {
            case 2436, 1792, 1624 :
                return true
                
            default:
                return false
            }
        }
        return false
        
    }
    
    //MARK:- Memory Management Methods
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    //MARK:- Zooming Methods
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return self.imageView
    }
    
    //MARK:- UIAction Methods
    @IBAction func btnBackClick(_ sender: Any) {
        self.navigationController?.popToRootViewController(animated: true)
    }
    
    @IBAction func btnReset(_ sender: Any) {
        self.scrollView.setZoomScale(1.0, animated: true)
    }
    
    //MARK:- Deallocate Methods
    deinit {
        print("deallocated")
    }
}
