//
//  PhotoCell.swift
//  CustomCamera
//
//  Created by Tankar Shah on 23/09/19.
//  Copyright © 2019 Tankar Shah. All rights reserved.
//

import UIKit
import Photos

class PhotoCell: UICollectionViewCell {
    @IBOutlet weak var imgPhoto: UIImageView!
    
}

//extension UIImageView{
//    func fetchImage(asset: PHAsset) {
//        let options = PHImageRequestOptions()
//        options.version = .original
//        PHImageManager.default().requestImageData(for: asset, options: options) { (image, str, orientation, data) in
//            guard let image = image else { return }
//            self.image = UIImage.init(data: image)!
//        }
//    }
//}

extension UIImageView{
    func fetchImage(asset: PHAsset, contentMode: PHImageContentMode, targetSize: CGSize) {
        let options = PHImageRequestOptions()
        options.version = .original
        PHImageManager.default().requestImage(for: asset, targetSize: targetSize, contentMode: contentMode, options: options) { image, _ in
            guard let image = image else { return }
            self.contentMode = .scaleAspectFill
            self.image = image
        }
    }
}
