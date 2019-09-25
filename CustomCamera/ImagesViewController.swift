//
//  ImagesViewController.swift
//  CustomCamera
//
//  Created by Tankar Shah on 23/09/19.
//  Copyright © 2019 Tankar Shah. All rights reserved.
//

import UIKit
import AVFoundation
import Photos


class ImagesViewController: UIViewController,UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout,updateGalleryDelegate {
    
    //MARK:- Param
    var allPhotos : PHFetchResult<PHAsset>? = nil
    var totalCount : Int = 0
    
    //MARK:- IBOutlet
    @IBOutlet weak var btnAddImage: UIButton!
    @IBOutlet weak var imageCollection: UICollectionView!
    @IBOutlet weak var navigationBarHeightConst: NSLayoutConstraint!
    @IBOutlet weak var lblNoData: UILabel!
    
    
    //MARK:- View Life Cycle Methods
    override func viewDidLoad() {
        super.viewDidLoad()
        self.setupInitial()
        if self.deviceIsiPhoneX(){
            self.navigationBarHeightConst.constant = 85
        } else {
            self.navigationBarHeightConst.constant = 65
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
    }
    
    //MARK:- Memory Management Methods
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    //MARK:- Custom Methods
    /** FUNCTION COMMENT
     Use : To hide Keyboard
     From where it is called : it is called from viewDidLoad
     Arguments : NA
     Return Type : Void
     **/
    func setupInitial(){
        
        let status = PHPhotoLibrary.authorizationStatus()
        switch status {
        case .authorized:
            let fetchOptions = PHFetchOptions()
            self.allPhotos = PHAsset.fetchAssets(with: .image, options: fetchOptions)
            self.totalCount = self.allPhotos!.count
            DispatchQueue.main.async {
                self.lblNoData.text = "Loading Images"
                self.imageCollection.reloadData()
                self.perform(#selector(self.rearrangeImages), with: nil, afterDelay: 0.5)
            }
            break
            
        case .denied, .restricted :
            //handle denied status
            self.lblNoData.text = "No Images Available"
            self.imageCollection.isHidden = true
            self.galleryEnable()
            break
        case .notDetermined:
            // ask for permissio 
            PHPhotoLibrary.requestAuthorization { status in
                switch status {
                case .authorized:
                    // as above
                    let fetchOptions = PHFetchOptions()
                    self.allPhotos = PHAsset.fetchAssets(with: .image, options: fetchOptions)
                    self.totalCount = self.allPhotos!.count
                    
                    DispatchQueue.main.async {
                        self.lblNoData.text = "Loading Images"
                        self.imageCollection.reloadData()
                        self.perform(#selector(self.rearrangeImages), with: nil, afterDelay: 0.5)
                    }
                    break
                case .denied, .restricted:
                    // as above
                    self.lblNoData.text = "No Images Available"
                    self.imageCollection.isHidden = true
                    break
                case .notDetermined:
                    // won't happen but still
                    self.lblNoData.text = "No Images Available"
                    self.imageCollection.isHidden = true
                    break
                }
            }
        }
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
    
    /** FUNCTION COMMENT
     Use : To show popup when camera is not enabled
     From where it is called : it is called from viewDidLoad notification
     Arguments : NA
     Return Type : Void
     **/
    @objc func galleryEnable() {
        let alert = UIAlertController(title: "Information", message: "Gallery access permission require", preferredStyle: .alert)
        // Create the actions
        let okAction = UIAlertAction(title: "Ok", style: UIAlertActionStyle.default) {
            UIAlertAction in
            if let aString = URL(string: UIApplicationOpenSettingsURLString) {
                UIApplication.shared.openURL(aString)
            }
            self.dismiss(animated: true, completion: nil)
        }
        let cancelAction = UIAlertAction(title: "Cancel", style: UIAlertActionStyle.cancel) {
            UIAlertAction in
            self.dismiss(animated: true, completion: nil)
        }
        
        // Add the actions
        alert.addAction(okAction)
        alert.addAction(cancelAction)
        
        self.present(alert, animated: true, completion: nil)
    }
    
    @objc func rearrangeImages(){
        if self.allPhotos!.count > 0{
            self.imageCollection.scrollToItem(at: IndexPath.init(row: self.allPhotos!.count - 1, section: 0), at: .bottom, animated: false)
            self.imageCollection.isHidden = false
        }
    }
    
    //MARK:- Collection View Delegate and Data Source Methods
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.totalCount
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let cell = self.imageCollection.dequeueReusableCell(withReuseIdentifier: "PhotoCell", for: indexPath) as! PhotoCell
        let asset = allPhotos?.object(at: indexPath.row)
        cell.imgPhoto.fetchImage(asset: asset!, contentMode: .aspectFit, targetSize: CGSize.init(width: cell.bounds.size.width + 50, height: cell.bounds.size.height + 50))
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let asset = allPhotos?.object(at: indexPath.row)
        let options = PHImageRequestOptions()
        options.version = .original
        PHImageManager.default().requestImageData(for: asset!, options: options) { (image, str, orientation, data) in
            guard let image = image else { return }
            if let viewWorkController = self.storyboard?.instantiateViewController(withIdentifier: "PreviewViewController") as? PreviewViewController {
                viewWorkController.img = UIImage.init(data: image)!
                self.navigationController?.pushViewController(viewWorkController, animated: true)
            }
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let width = (UIScreen.main.bounds.width - 4) / 4
        return CGSize(width: width, height: width)
    }
    
    //MARK:- Delegate Methods for Update images
    func updateAllImages() {
        self.setupInitial()
    }
    
    //MARK:- UIAction Methods
    @IBAction func btnAddImageClick(_ sender: Any) {
        if let viewWorkController = self.storyboard?.instantiateViewController(withIdentifier: "CaptureImageViewController") as? CaptureImageViewController {
            viewWorkController.delegate = self
            self.navigationController?.pushViewController(viewWorkController, animated: true)
        }
    }
    
    //MARK:- Deallocate Methods
    deinit {
        print("deallocated")
    }
}
