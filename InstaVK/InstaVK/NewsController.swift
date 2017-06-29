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
    
    var posts = [Post]()
    var profiles = [Int:Profile]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let nib = UINib (nibName: "PictureCell", bundle: nil)
        self.tableView.register(nib, forCellReuseIdentifier: pictureCellIdentifier)
        
        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(handleRefresh), for: .valueChanged)
        tableView.refreshControl = refreshControl
        
        fetchPosts()
        
        
    }
    
    func handleRefresh() {
        print("Attempting to refresh feed")
        fetchPosts()
    }
    
    //FORCED to use api request vs sdk due to unavailable newsfeed method in sdk
    func fetchPosts() {
        guard let vkAccessToken = VKSdk.accessToken().accessToken else {
            return
        }
        guard let url = vkApiUrlBuilder(vkApiMethod: "newsfeed.get",
                                        queryItems: ["filters":"wall_photo",
                                                     "count":"10",
                                                     "source_ids":"friends,following",
                                                     "access_token":vkAccessToken])
            else {
                return
        }
        
        
        URLSession.shared.dataTask(with: url, completionHandler: { (data, response, error) in
            if error != nil {
                print(error ?? "")
                return
            }
            
            do {
                
                self.posts.removeAll()
                self.profiles.removeAll()
                
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
               
                //Fixed reload data with sync queue (not sure if it is correct)
                DispatchQueue.main.async(execute: { () -> Void in
                    self.tableView?.reloadData()
                })
                self.tableView.refreshControl?.endRefreshing()
                
            } catch let jsonError {
                print(jsonError)
            }
        }) .resume()
    }
    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    // MARK: - Table view data source
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        var numOfSections: Int = 0
        if posts.count>0
        {
            tableView.separatorStyle = .singleLine
            tableView.separatorInset = .zero
            numOfSections = 1
            tableView.backgroundView = nil
        }
        else
        {
            let noDataLabel: UILabel = UILabel(frame: CGRect(x: 0,
                                                             y: 0,
                                                             width: tableView.bounds.size.width,
                                                             height: tableView.bounds.size.height))
            noDataLabel.text = "No data to display :("
            noDataLabel.textColor = UIColor.black
            noDataLabel.textAlignment = .center
            tableView.backgroundView = noDataLabel
            tableView.separatorStyle = .none
        }
        return numOfSections
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return posts.count
    }
    
    
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        let cell = tableView .dequeueReusableCell(withIdentifier: pictureCellIdentifier,
                                                  for: indexPath)

        if let newsCell = cell as? PictureCell {
            newsCell.post = posts[indexPath.row]
            newsCell.delegate = self
            if let postOwnerFirstName = profiles[posts[indexPath.row].ownerId]?.firstName, let postOwnerSecondName = profiles[posts[indexPath.row].ownerId]?.lastName {
                newsCell.postUserFirstNameLastName.text = postOwnerFirstName + " " + postOwnerSecondName
            } else {
                newsCell.postUserFirstNameLastName.text = "Unavailable"
            }
            if let postOwnerAvatarUrl = profiles[posts[indexPath.row].ownerId]?.photoUrl {
                newsCell.postUserAvatar.setShowActivityIndicator(true)
                newsCell.postUserAvatar.setIndicatorStyle(.gray)
                newsCell.postUserAvatar.sd_setImage(with: URL(string: postOwnerAvatarUrl))
            } else {
                newsCell.postUserAvatar.image = #imageLiteral(resourceName: "VKSadDogSquare")
            }
            
            newsCell.postPicture.setShowActivityIndicator(true)
            newsCell.postPicture.setIndicatorStyle(.gray)
            let scale: CGFloat = CGFloat(posts[indexPath.row].imageWidth)/UIScreen.main.bounds.width
            newsCell.postPictureHeight.constant = CGFloat(posts[indexPath.row].imageHeight)/scale
            newsCell.postPicture.sd_setImage(with: URL(string: posts[indexPath.row].imageUrl_604))

            newsCell.postLikeButton.setImage(posts[indexPath.row].userLikes == 1 ? #imageLiteral(resourceName: "HeartFilledRed") : #imageLiteral(resourceName: "HeartEmpty"), for: .normal)
        }
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableViewAutomaticDimension
        
    }
    
    override func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return 300
    }
    
    // MARK: TapCommentsButton
    func didTapCommentsButton(sender: PictureCell) {
        let commentsControler = CommentsController()
        if let post = sender.post {
            commentsControler.post = post
        }
        navigationController?.pushViewController(commentsControler, animated: true)
    }
    
    // MARK: TapLikeButton
    func didTapLikeButton(sender: PictureCell) {
        
        guard let indexPath = tableView.indexPath(for: sender) else { return }
        var post = self.posts[indexPath.item]
        guard let owner_id = sender.post?.ownerId else { return }
        guard let item_id = sender.post?.postId else { return }
        guard let access_key = sender.post?.access_key else { return }
        
        var url: URL?
        
        if post.userLikes == 0 {
            url = vkApiUrlBuilder(vkApiMethod: "likes.add",
                                  queryItems: ["type":"photo",
                                               "owner_id": String(owner_id),
                                               "item_id": String(item_id),
                                               "access_key": String(access_key),
                                               "access_token":VKSdk.accessToken().accessToken])
        }
        else {
            url = vkApiUrlBuilder(vkApiMethod: "likes.delete",
                                  queryItems: ["type":"photo",
                                               "owner_id": String(owner_id),
                                               "item_id": String(item_id),
                                               "access_key": String(access_key),
                                               "access_token":VKSdk.accessToken().accessToken])
        }
        
        if let url = url {
            URLSession.shared.dataTask(with: url, completionHandler: { (data, response, error) in
                if error != nil {
                    print(error ?? "")
                    return
                }
                post.userLikes = 1 - post.userLikes
                self.posts[indexPath.item] = post
                
                DispatchQueue.main.async(execute: { () -> Void in
                    self.tableView?.reloadRows(at: [indexPath], with: .none)
                })
                
            }).resume()
        }
    }
    
    
    // MARK: LogOut
    @IBAction func logOut(_ sender: Any) {
        let alertVC = UIAlertController(title: nil,
                                        message: nil,
                                        preferredStyle: UIAlertControllerStyle.actionSheet)
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
    
    // MARK: HandleCamera
    @IBAction func handleCamera(_ sender: Any) {
        let cameraController = CameraController()
        present(cameraController, animated: true, completion: nil)
    }
}
