//
//  ViewController.swift
//  GuessFlower
//
//  Created by Carlos Herrera Somet on 3/4/18.
//  Copyright © 2018 Carlos H Somet. All rights reserved.
//

import UIKit
import Alamofire
import SimpleAnimation
import SwiftyJSON
import SDWebImage
import CoreML
import Vision
import RSLoadingView

class ViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    //MARK:- IBOUTLETS
    @IBOutlet weak var flowerImage: UIImageView!
    @IBOutlet weak var flowerName: UILabel!
    @IBOutlet weak var wikiText: UILabel!
    
    let imagePicker = UIImagePickerController()
    let loadingView = RSLoadingView()
    
    var imageTaken : UIImage?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //initializing image picker
        imagePicker.delegate = self
        imagePicker.allowsEditing = true
        imagePicker.sourceType = .camera
        
        initLoadingView()
        
    }

    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
       
        startLoading()
        
        imageTaken = info[UIImagePickerControllerEditedImage] as? UIImage
    
        guard let ciimage = CIImage(image: imageTaken!) else { fatalError("Error converting CIImage...") }

        dismiss(animated: false) {
            self.flowerImage.fadeIn(duration: 1, delay: 0.5, completion: nil)
            self.flowerName.fadeIn(duration: 1, delay: 0.5, completion: nil)
        }
        
        detect(image: ciimage)

        
    }
    
    /**
     It obtains information from wikipedia request. It will set the value for text labels and images from the web.
     - parameter flower: The String name of the flower seached for.
     */
    func getWikiInfoOfFlower(for flower: String){
    
        let parameters : [String:String] = [
            "format" : "json",
            "action" : "query",
            "prop" : "extracts|pageimages",
            "exintro" : "",
            "explaintext" : "",
            "titles" : flower,
            "indexpageids" : "",
            "redirects" : "1",
            "pithumbsize" : "500"
            ]
        
        Alamofire.request(CONST.wikipediaURl, method: .get, parameters: parameters).responseJSON { (response) in
            
            if response.result.isSuccess{

                let flowerInfoJSON : JSON = JSON(response.result.value!)
                let pageid = flowerInfoJSON["query"]["pageids"][0].stringValue
                
                let desc = flowerInfoJSON["query"]["pages"][pageid]["extract"].stringValue
                
                if desc == "" {
                    self.wikiText.text = "No description found for this example. Sorry!"
                } else {
                    self.wikiText.text = desc
                }
                
                self.flowerName.text = flowerInfoJSON["query"]["pages"][pageid]["title"].stringValue
                
                let urlString = flowerInfoJSON["query"]["pages"][pageid]["thumbnail"]["source"].stringValue
                
                self.flowerImage.sd_setImage(with: URL(string: urlString), completed: { (image, error, imageCacheType, url) in
                    
                    if error == nil {
    
                        self.stopLoading()
                        
                    } else {
                        self.flowerImage.image = self.imageTaken
                        self.stopLoading()
                    }
                })
            }
        }
        
    }
    
    
    /**
     Detects the image using the model (coreML): FlowerClassifier.mlmodel
     - parameter image: CIImage needed to detect.
     */
    func detect(image: CIImage){
        
        guard let model = try? VNCoreMLModel(for: FlowerClassifier().model) else {return}
        
        let request = VNCoreMLRequest(model: model) { (request, error) in
            
            guard let classification = request.results?.first as? VNClassificationObservation else { return }
           
            self.getWikiInfoOfFlower(for: classification.identifier.capitalized)
        }
        
        
        let handler = VNImageRequestHandler(ciImage: image)
        
        do{
            try handler.perform([request])
            
        }catch{
            print("Error handle...")
        }
    }

    @IBAction func takeFlowerPicture(_ sender: UIBarButtonItem) {
        present(imagePicker,animated: true, completion: nil)
    }
    
    func initLoadingView(){
        
        loadingView.mainColor   = UIColor.white
        loadingView.speedFactor = 2.0
        loadingView.variantKey  = "inAndOut"
        loadingView.shouldTapToDismiss = true
        
    }
    
    
    func startLoading(){
        loadingView.showOnKeyWindow()
    }
    
    func stopLoading(){
        loadingView.hide()
    }

}

