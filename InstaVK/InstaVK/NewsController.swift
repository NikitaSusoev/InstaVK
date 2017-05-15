//
//  NewsController.swift
//  InstaVK
//
//  Created by Никита on 27.03.17.
//  Copyright © 2017 Nikita Susoev. All rights reserved.
//

import UIKit
import VK_ios_sdk
import SDWebImage

fileprivate var SCOPE: [Any]? = nil

class NewsController: UITableViewController, PictureCellDelegate {
    
    let pictureCellIdentifier = "PictureCell"

    //Array of cats to make the day, actually for test purposes here
    var imageURLs = ["http://www.pravmir.ru/wp-content/uploads/2015/11/image-original.jpg", "http://redcat7.ru/wp-content/uploads/2014/01/motivator-s-kotom-pogovori.jpg", "https://4tololo.ru/files/styles/large/public/images/20141911123228.jpg?itok=gdc3Arzv", "http://www.sostav.ru/blogs/images/posts/15/29708.jpg", "http://www.nexplorer.ru/load/Image/1113/koshki_9.jpg", "http://storyfox.ru/wp-content/uploads/2015/11/shutterstock_265075847-696x528.jpg", "https://i.ytimg.com/vi/BhJO2Urrq94/hqdefault.jpg", "http://hitgid.com/images/коты-4.jpg", "http://catscountry.ru/wp-content/uploads/2015/10/2.jpg", "http://bm.img.com.ua/nxs/img/prikol/images/large/4/3/160134_288725.jpg"]
    
    var posts = [Post]()
    var profiles = [Int:Profile]()

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.hidesBarsOnSwipe = true
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false
        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        let nib = UINib (nibName: "PictureCell", bundle: nil)
        self.tableView.register(nib, forCellReuseIdentifier: pictureCellIdentifier)
        
        fetchPosts()
        
        
    }
        
    //FORCED to use api request vs sdk due to unavailable newsfeed method in sdk
    func fetchPosts() {
        guard let vkAccessToken = VKSdk.accessToken().accessToken else {
            return
        }
        guard let url = vkApiUrlBuilder(vkApiMethod: "newsfeed.get", queryItems: ["filters":"photo", "count":"10", "access_token":vkAccessToken]) else {
            return
        }
        
        URLSession.shared.dataTask(with: url, completionHandler: { (data, response, error) in
            if error != nil {
                print(error ?? "")
                return
            }
            
            do {
                //в JSONе приходит отдельный словарь на профайлы и отдельный на фотографии
                let json = try JSONSerialization.jsonObject(with: data!, options: .mutableContainers)
                guard let jsonDict = json as? [String: Any] else { return }
                guard let responseDict = jsonDict["response"] as? [String: Any] else { return }
                guard let profilesDict = responseDict["profiles"] as? [[String: Any]] else { return }
                //добавляем профайл в словарь наших профайлов чтобы подтягивать оттуда информацию о пользователе
                for profile in profilesDict {
                    if let profileId = profile["uid"] as? Int {
                        self.profiles[profileId] = Profile(dictionary: profile)
                    }
                }
                guard let itemsDict = responseDict["items"] as? [[String: Any]] else { return }
                //из items вытягиваем информацию о постах и добавляем в наш массив постов
                for item in itemsDict {
                    if let photosArray = item["photos"] as? [Any] {
                        for photo in photosArray {
                            if let photoDictionary = photo as? [String : Any] {
                                let post = Post(dictionary: photoDictionary)
                                self.posts.append(post)
                            }
                        }
                    }
                }
                DispatchQueue.main.async(execute: { () -> Void in
                    self.tableView?.reloadData()
                })
            } catch let jsonError {
                print(jsonError)
            }
        }) .resume()
    }
    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return posts.count
    }
    

    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView .dequeueReusableCell(withIdentifier: pictureCellIdentifier, for: indexPath)
        if let newsCell = cell as? PictureCell {
        newsCell.delegate = self
        if let postOwnerFirstName = profiles[posts[indexPath.row].ownerId]?.firstName, let postOwnerSecondName = profiles[posts[indexPath.row].ownerId]?.lastName {
            newsCell.postUserFirstNameLastName.text = postOwnerFirstName + " " + postOwnerSecondName
        } else {
            newsCell.postUserFirstNameLastName.text = "Unawailable"
        }
        if let postOwnerAvatarUrl = profiles[posts[indexPath.row].ownerId]?.photoUrl_50 {
            newsCell.postUserAvatar.setShowActivityIndicator(true)
            newsCell.postUserAvatar.setIndicatorStyle(.gray)
            newsCell.postUserAvatar.sd_setImage(with: URL(string: postOwnerAvatarUrl))
        } else {
            newsCell.postUserAvatar.image = #imageLiteral(resourceName: "error404")
        }
        //if let postLikedByUser = profiles[posts[indexPath.row].likes[]
        
        //TEST
        //let imageView = newsCell.postPicture!
            
            //sd web cache manager что-то там
            newsCell.postPicture.setShowActivityIndicator(true)
            newsCell.postPicture.setIndicatorStyle(.gray)
//            newsCell.postPicture.contentMode = .scaleAspectFit
            let scale: CGFloat = CGFloat(posts[indexPath.row].imageWidth)/UIScreen.main.bounds.width
//            print(scale)
            newsCell.postPictureHeight.constant = CGFloat(posts[indexPath.row].imageHeight)/scale
            newsCell.postPicture.sd_setImage(with: URL(string: posts[indexPath.row].imageUrl_604), completed: { (image, error, cached, url) in
                if image != nil{
                    if cached.rawValue == 1 {
                        DispatchQueue.main.async(execute: { () -> Void in
                            //self.tableView.reloadData()
                            self.tableView.beginUpdates()
                            self.tableView.reloadRows(
                                at: [indexPath],
                                with: .fade)
                            self.tableView.endUpdates()
                        })
                    }
                } else {
                    newsCell.postPicture.image = #imageLiteral(resourceName: "error404")
                }
            })
            }
        
        //if let
        return cell
    }
    
//    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
//        let scale : CGFloat = #imageLiteral(resourceName: "Image").size.width/UIScreen.main.bounds.width
//        return #imageLiteral(resourceName: "Image").size.height/scale + 80 + 32
//    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableViewAutomaticDimension
        
    }
    
    override func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return 300
    }
    
    func didTapButton(sender: UITableViewCell) {
        let commentsControler = CommentsController()
        navigationController?.pushViewController(commentsControler, animated: true)
    }
    
    
    // MARK: LogOut button for test purposes
    @IBAction func logOut(_ sender: Any) {
        let alertVC = UIAlertController(title: nil, message: nil, preferredStyle: UIAlertControllerStyle.actionSheet)
        let logOutButton = UIAlertAction(title: "LogOut", style: .destructive, handler: logOutToLoginScreen)
        let dismiss = UIAlertAction(title: "Cancel", style: UIAlertActionStyle.cancel, handler: nil)
        alertVC.addAction(logOutButton)
        alertVC.addAction(dismiss)
        self.present(alertVC, animated: true, completion: nil)
        
    }
    
    func logOutToLoginScreen(alert: UIAlertAction){
        VKSdk.forceLogout()
        let lc = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "LoginViewController")
        self.present(lc, animated: true, completion: nil)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super .viewWillDisappear(animated)
        self.navigationController?.isNavigationBarHidden = false
    }
    
    
    /*
    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    */

    /*
    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Delete the row from the data source
            tableView.deleteRows(at: [indexPath], with: .fade)
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    */

    /*
    // Override to support rearranging the table view.
    override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        return true
    }
    */

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
