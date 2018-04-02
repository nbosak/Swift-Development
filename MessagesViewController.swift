//
//  MessagesViewController.swift
//  AppKit
//
//  Created by Nicholas Bosak on 9/8/16.
//

import UIKit
import ModelKit

class MessagesViewController: UIViewController {

    var messageManager: MessageManager!

    fileprivate let filterShouldRotate = false

    fileprivate lazy var searchBar = UISearchBar(frame: CGRect.zero)

    @IBOutlet weak var messageTable: UITableView!
    @IBOutlet weak var messagePicker: UIPickerView! {
        didSet {
            messagePicker.backgroundColor = .groupTableViewBackground
        }
    }

    @IBOutlet weak var filterChevron: UIBarButtonItem! {
        didSet {
            let icon = (UIImage(named: "msg_filter") ?? UIImage(named: "chevron_down"))!.withRenderingMode(.alwaysTemplate)
            let iconButton = UIButton(frame: self.setFilterFrame())

            iconButton.setBackgroundImage(icon, for: .normal)
            iconButton.tintColor = .white
            iconButton.addTarget(self, action: #selector(toggleFilter), for: .touchUpInside)

            filterChevron.customView = iconButton

        }
    }

    fileprivate func setFilterFrame() -> CGRect {
        guard let navFrame = self.navigationController?.navigationBar.frame else { return CGRect.zero }

        return CGRect(origin: CGPoint.zero,
                      size: CGSize(width: floor(navFrame.height * 0.70),
                                   height: floor(navFrame.height * 0.70)))
    }

    fileprivate lazy var noHistoryLabel: UILabel = {
        let label = UILabel(frame: CGRect(x: 0, y: 0, width: self.view.bounds.width, height: self.view.bounds.height))

        label.text = "No Messages"
        label.textColor = .black
        label.numberOfLines = 0
        label.textAlignment = .center
        label.font = UIFont.systemFont(ofSize: 22)
        label.sizeToFit()

        return label
    }()

    fileprivate lazy var endOfHistoryLabel: UILabel = {
        let label = UILabel(frame: CGRect.zero)

        label.text = "End of Messages"
        label.textColor = .lightGray
        label.numberOfLines = 0
        label.textAlignment = .center
        label.font = UIFont.systemFont(ofSize: 14)
        label.sizeToFit()

        return label
    }()

    //Picker options
    let pickerData = [MessageFilter.none, MessageFilter.system, MessageFilter.blocked]

    fileprivate var isFetching = false {
        didSet {
            // turn spinner on or off
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        messagePicker.delegate = self
        messagePicker.dataSource = self
        rotate(.down, animated: false)

        messageTable.dataSource = self
        messageTable.delegate = self

        // This prevents flashing a view full of empty rows
        messageTable.tableFooterView = UIView(frame: CGRect.zero)

        searchBar.delegate = self
        searchBar.placeholder = "Search"

        setupNavigationBar()

        messageManager.didGetMessages = {
            self.messageTable.backgroundView = self.messageManager.messages.isEmpty ? self.noHistoryLabel : nil

            if self.messageManager.hasMoreHistory || self.messageManager.messages.isEmpty {
                self.messageTable.tableFooterView = UIView(frame: CGRect.zero)
            } else {
                self.messageTable.tableFooterView = self.endOfHistoryLabel
            }
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        rotate(.down, animated: false)
        dismissKeyboard()

        if let selected = messageTable.indexPathForSelectedRow {
            self.messageTable.deselectRow(at: selected, animated: true)
        }

        UIApplication.shared.statusBarStyle = .lightContent

        messageManager.getNewMessages(limit: messageManager.apiLimit, success: { newMessages, unread in
            self.messageManager.messages = newMessages
            self.messageTable.reloadData()
            self.updateBadge(unreadCount: unread)

            self.isFetching = false
        }, failure: { self.isFetching = false }, error: { _ in self.isFetching = false })

        isFetching = true
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {

        if segue.identifier == "MessageDetailSegue" {
            guard let dest = segue.destination as? MessageDetailViewController,
                let indexPath = messageTable.indexPathForSelectedRow else { return }

            dest.message = messageManager.messages[indexPath.row]
        }
    }

    fileprivate enum RotationDirection {
        case up
        case down
    }

    @objc private func toggleFilter() {
        searchBar.resignFirstResponder()
        dismissKeyboard()

        if filterShouldRotate {
            filterChevron.customView?.frame = setFilterFrame()
        }

        let chevIsUp = messagePicker.frame.origin.y < self.view.frame.height - (tabBarController?.tabBar.frame.height ?? 0)

        if chevIsUp {
            rotate(.down)

        } else {
            rotate(.up)
        }
    }

    fileprivate func rotate(_ direction: RotationDirection, animated: Bool = true) {
        let tabHeight = self.tabBarController?.tabBar.frame.height ?? 0
        let duration = animated ? 0.3 : 0.0

        let endAngle: CGFloat = direction == .up ? 180.001 : 0
        let endOrigin: CGFloat  = direction == .up ? self.messagePicker.frame.height : 0

        UIView.animate(withDuration: duration,
                       delay: 0,
                       options: .curveEaseInOut,
                       animations: {
                        if self.filterShouldRotate {
                            self.filterChevron.customView?.transform = CGAffineTransform(rotationAngle: endAngle.degreesToRadians)
                        }

                        self.messagePicker.frame = CGRect(x: self.messagePicker.frame.origin.x,
                                                          y: self.view.frame.height - tabHeight - endOrigin,
                                                          width: self.messagePicker.frame.width,
                                                          height: self.messagePicker.frame.height)
        })
    }

    private func setupNavigationBar() {
        navigationItem.titleView = searchBar
        self.navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)
    }

    // Validate and Update the Tab Bar Item Badge
    func updateBadge(unreadCount: Int) {

        if #available(iOS 10.0, *) {
            // for iOS 10, use the Apple UITabBar API
            self.navigationController?.tabBarItem.badgeValue = unreadCount > 0 ? "\(unreadCount)" : nil
        } else {
            // Fallback on earlier versions to the UITabBar extension for custom badges
            self.navigationController?.tabBarController?.setBadges([0, unreadCount, 0])
        }
    }

    // Scrolls to top of table view
    fileprivate func scrollToTop(_ animated: Bool = false) {
        messageTable.scrollToRow(at: IndexPath(row: 0, section: 0), at: .none, animated: false)
    }
}

extension MessagesViewController: UITableViewDelegate, UITableViewDataSource {

    //MARK: Table view data source and delegate
    func numberOfSections(in tableView: UITableView) -> Int {

        return self.messageManager.messages.isEmpty ? 0 : 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.messageManager.messages.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.row == 0 {

            let cell = tableView.dequeueReusableCell(withIdentifier: "MessagePreviewCell", for: indexPath) as! MessagePreviewCell
            cell.message = self.messageManager.messages[indexPath.row]
            return cell

        } else {

            let cell = tableView.dequeueReusableCell(withIdentifier: "MessageCell", for: indexPath)
            let msg = self.messageManager.messages[indexPath.row]

            cell.detailTextLabel?.text = msg.timestamp.short
            cell.detailTextLabel?.font = msg.isRead ? cell.detailTextLabel?.font.regular : cell.detailTextLabel?.font.bold

            cell.textLabel?.text = msg.title
            cell.textLabel?.font = msg.isRead ? cell.textLabel?.font.regular : cell.textLabel?.font.bold

            return cell
        }
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {

        // Hide filter picker on cell selection
        searchBar.resignFirstResponder()
        rotate(.down)

        // Go to the detail view
        self.performSegue(withIdentifier: "MessageDetailSegue", sender: self)

        // Update the message's isRead status behind the scenes
        messageManager.markAsRead(message: messageManager.messages[indexPath.row], success: {

            if !self.messageManager.messages[indexPath.row].isRead {
                self.messageManager.messages[indexPath.row].isRead = true
                tableView.reloadRows(at: [indexPath], with: .none)
                self.updateBadge(unreadCount: Int(self.navigationController?.tabBarItem.badgeValue ?? "0")! - 1)
            }

            self.isFetching = false

        }, failure: { self.isFetching = false }, error: { _ in self.isFetching = false })

        self.isFetching = true
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return indexPath.row == 0 ? UITableViewAutomaticDimension : 54.0
    }

    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return indexPath.row == 0 ? 120.0 : UITableViewAutomaticDimension
    }
}

// MARK: - Picker View Delegate & Data Source
extension MessagesViewController: UIPickerViewDelegate, UIPickerViewDataSource {

    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }

    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return pickerData.count

    }

    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return pickerData[row] == .none ? "All" : pickerData[row].rawValue.capitalized
    }

    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {

        messageManager.getMessages(limit: messageManager.apiLimit, filter: pickerData[row], search: "", success: { newMessages, unread in
            self.messageManager.messages = newMessages
            self.messageTable.reloadData()
            if !newMessages.isEmpty { self.scrollToTop() }

            self.isFetching = false

        }, failure: { self.isFetching = false }, error: { _ in self.isFetching = false })

        self.isFetching = true
    }
}

//MARK: UISearchBar delegate
extension MessagesViewController: UISearchBarDelegate {

    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        rotate(.down)
    }

    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {

        // Hide the picker when the search begins
        rotate(.down)
        //guard !isFetching else { return }

        messageManager.getMessages(limit: messageManager.apiLimit, filter: .none, search: searchText, success: { newMessages, unread in
            self.messageManager.messages = newMessages
            self.messageTable.reloadData()

            if !newMessages.isEmpty { self.scrollToTop() }

            self.isFetching = false

        }, failure: { self.isFetching = false }, error: { _ in self.isFetching = false })

        self.isFetching = true
    }
}

// MARK: - Scroll view delegate
extension MessagesViewController: UIScrollViewDelegate {

    func scrollViewDidScroll(_ scrollView: UIScrollView) {

        guard !isFetching && self.messageManager.hasMoreHistory else { return }

        let position = scrollView.contentOffset.y
        let contentHeight = scrollView.contentSize.height - self.messageTable.frame.height - self.messageTable.rowHeight

        if position >= contentHeight {
            messageManager.getMoreMessages(limit: messageManager.apiLimit, success: { newMessages, _ in
                self.messageManager.messages += newMessages
                self.messageTable.reloadData()

                self.isFetching = false

            }, failure: { self.isFetching = false }, error: { _ in self.isFetching = false })

            isFetching = true
        }
    }
}
