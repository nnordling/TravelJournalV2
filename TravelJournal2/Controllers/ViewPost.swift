//
//  ViewPost.swift
//  TravelJournal2
//
//  Created by Niclas Nordling on 2019-01-25.
//  Copyright © 2019 Niclas Nordling. All rights reserved.
//

import UIKit
import FacebookShare

class ViewPost: UIViewController, PostDelegate {

    fileprivate var orientation: UIDeviceOrientation {
        return UIDevice.current.orientation
    }
    
    var backgroundImage = UIImageView()
    var blurEffect = UIBlurEffect(style: UIBlurEffect.Style.dark)
    var blurEffectView = UIVisualEffectView()
    var postImage = UIImageView()
    var postTitle = UILabel()
    var postDate = UILabel()
    var postText = UITextView()
    var shareBtn = UIButton()
    var locationBtn = UIButton()
    var editPostBtn = UIBarButtonItem()
    
    let data = TripData()
    
    var currentPost = 0
    var postId = ""
    var longitude = ""
    var latitude = ""
    var userEmail = ""

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        NotificationCenter.default.addObserver(self, selector: #selector(setupUI), name: UIDevice.orientationDidChangeNotification, object: nil)
        data.loadOnePost(postId: postId)
        blurEffectView.effect = blurEffect
        setupUI()
        data.postDel = self
    }

    func setupBackground() {
        backgroundImage.frame = UIScreen.main.bounds
        backgroundImage.contentMode = .scaleAspectFill
        backgroundImage.clipsToBounds = true
        backgroundImage.image = UIImage(named: "background2")
        
        blurEffectView.frame = view.bounds
        
        view.addSubview(backgroundImage)
        backgroundImage.addSubview(blurEffectView)
    }

    @objc func addViewPostUI() {
        let screenHeight = UIScreen.main.bounds.size.height
        let screenWidth = UIScreen.main.bounds.size.width
        
        guard let navbarHeight = self.navigationController?.navigationBar.bounds.size.height else {return}
        let statusbarHeight = UIApplication.shared.statusBarFrame.height
        
        let width = view.frame.width - 20
        var y = navbarHeight + statusbarHeight + 10
        var landscapeTitle: CGFloat = 0 // Hack to make title 10px below image in landscape
        
        if orientation != .portrait {
            landscapeTitle = 10
        }
        
        // Edit Post button
        editPostBtn.style = .plain
        editPostBtn.title = NSLocalizedString("Edit", comment: "")
        editPostBtn.target = self
        editPostBtn.action = #selector(editPost)
        
        self.navigationItem.rightBarButtonItem = editPostBtn
        
        // Post Image
        postImage.frame = (CGRect(x: 10, y: y, width: width, height: view.frame.height*0.40))
        postImage.contentMode = .scaleAspectFill
        postImage.layer.cornerRadius = 10.0
        postImage.clipsToBounds = true

        view.addSubview(postImage)
        y += postImage.bounds.size.height
        y += landscapeTitle
        
        // Post title
        postTitle.frame = (CGRect(x: 10, y: y, width: width, height: view.frame.height*0.06))
        postTitle.textColor = UIColor.white
        postTitle.font = UIFont(name: "AvenirNext-Medium", size: 25.0)
        view.addSubview(postTitle)
        y += postTitle.bounds.size.height
        
        // Post date
        postDate.frame = (CGRect(x: 10, y: y, width: width, height: view.frame.height*0.03))
        postDate.textColor = UIColor.white
        postDate.font = UIFont(name: "AvenirNext-MediumItalic", size: 12.0)
        view.addSubview(postDate)
        y += postDate.bounds.size.height
        
        // Post text
        postText.frame = (CGRect(x: 10, y: y, width: width, height: view.frame.height*0.40))
        postText.isEditable = false
        postText.isSelectable = true
        postText.textColor = UIColor.white
        postText.backgroundColor = UIColor.clear
        view.addSubview(postText)
        y += postText.bounds.size.height
        
        // Share icon
        shareBtn.setImage(UIImage(named: "share"), for: .normal)
        shareBtn.addTarget(self, action: #selector(sharePost), for: .touchUpInside)
        shareBtn.frame = CGRect(x: 20, y: screenHeight - 52, width: 32, height: 32)
        view.addSubview(shareBtn)
        
        // Location icon
        locationBtn.setImage(UIImage(named: "location"), for: .normal)
        locationBtn.addTarget(self, action: #selector(postLocation), for: .touchUpInside)
        locationBtn.frame = CGRect(x: screenWidth - 52, y: screenHeight - 52, width: 32, height: 32)
        view.addSubview(locationBtn)
    }

    @objc func setupUI() {
        guard !orientation.isFlat else { return }
        setupBackground()
        addViewPostUI()
    }

    @objc func sharePost() {
        if let img = postImage.image {
            let photo = Photo(image: img, userGenerated: false)
            let content = PhotoShareContent(photos: [photo])
            let shareDialog = ShareDialog(content: content)
            
            do {
                try shareDialog.show()
            } catch {
                print("Facebook share error \(error)")
            }
        }
    }

    @objc func postLocation() {
        let showMap = ShowMap()
        showMap.lat = latitude
        showMap.long = longitude
        
        self.navigationController?.pushViewController(showMap, animated: true)
    }
    
    @objc func editPost() {
        let editPost = EditPost()
        editPost.postId = postId

        self.navigationController?.pushViewController(editPost, animated: true)
    }
    
    func SetPostData(description:[String:Any]) {
        postTitle.text = description["postTitle"] as? String
        postDate.text = description["postDate"] as? String
        postText.text = description["postText"] as? String
        longitude = description["postLong"] as? String ?? ""
        latitude = description["postLat"] as? String ?? ""
        userEmail = description["userEmail"] as? String ?? ""
    }
    
    func setPostImg(img:UIImage) {
        let postImg = img
        
        let inW = postImg.size.width
        let inH = postImg.size.height
        let inRatio = inH/inW

        let viewW = postImage.frame.size.width
        let viewH = postImage.frame.size.height
        let viewRatio = viewH/viewW

        var offsetX:CGFloat = 0.0
        var offsetY:CGFloat  = 0.0
        var outW:CGFloat  = 0.0
        var outH:CGFloat  = 0.0

        if  inRatio > viewRatio {
            outW = viewW
            outH = inRatio*outW
            offsetX = 0.0
            offsetY = (viewH-outH)/2.0
        } else {
            outH = viewH
            outW = outH/inRatio
            offsetY = 0.0
            offsetX = (viewW-outW)/2.0
        }

        UIGraphicsBeginImageContext(CGSize(width: viewW, height: viewH))

        postImg.draw(in: CGRect(x: offsetX, y: offsetY, width: outW, height: outH))
        postImage.image = postImg
        UIGraphicsEndImageContext()
    }
}