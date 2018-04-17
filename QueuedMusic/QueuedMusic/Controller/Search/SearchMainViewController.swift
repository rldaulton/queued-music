//
//  SearchMainViewController.swift
//  QueuedMusic
//
//  Created by Anton Dolzhenko on 30.01.17.
//  Copyright © 2017 Red Shepard LLC. All rights reserved.
//

import UIKit

final class SearchMainViewController: BaseViewController {
    
    @IBOutlet fileprivate var searchBarContainerView: UIView!
    @IBOutlet fileprivate var emptyResultsView: UIView!
    
    var filterString = ""
    
    lazy var searchResultsController: SearchResultsTableViewController = {
        let storyboard = UIStoryboard(storyboard: .Search)
        let vc:SearchResultsTableViewController = storyboard.instantiateViewController()
        vc.mainViewController = self
        return vc
    }()
    
    lazy var searchController: UISearchController = {
        let searchController = UISearchController(searchResultsController: self.searchResultsController)
        searchController.searchResultsUpdater = self
        searchController.hidesNavigationBarDuringPresentation = false
        searchController.dimsBackgroundDuringPresentation = false
        searchController.searchBar.delegate = self
        return searchController
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let searchBar = searchController.searchBar
        searchBar.autocapitalizationType = .none
        searchBar.autocorrectionType = .no
        searchBar.spellCheckingType = .no
        searchBar.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        searchBar.keyboardAppearance = .dark
        self.navigationItem.titleView = searchBar
        searchBar.sizeToFit()
        
        definesPresentationContext = true
        
    }
}

extension SearchMainViewController {
    func showProfile(_ profile: Any) {
        searchController.isActive = false
    }
    
    func showSong(_ song: Any) {
        searchController.isActive = false
    }
}

// MARK: - UISearchResultsUpdating
extension SearchMainViewController: UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {
        NSObject.cancelPreviousPerformRequests(withTarget: self,
                                               selector: #selector(self.search(searchTerm:)),
                                               object: filterString)
        self.perform(#selector(self.search(searchTerm:)),
                     with: searchController.searchBar.text,
                     afterDelay: 0.5)
        filterString = searchController.searchBar.text!
        searchResultsController.clear()
    }
    
    func search(searchTerm:String){
        if searchTerm.isEmpty { return }
        searchResultsController.filterData(searchTerm)
    }
    
    func handleEmptyResults(_ displayedResults: Int) {
        let showEmptyResultsView = (searchController.isActive && displayedResults == 0)
        emptyResultsView.isHidden = !showEmptyResultsView
    }
}

// MARK: - UISearchBarDelegate
extension SearchMainViewController: UISearchBarDelegate {
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        searchController.isActive = false
        searchResultsController.cancelSearh()
    }
    
    func searchBar(_ searchBar: UISearchBar, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        return true
    }
    
    func searchBarShouldBeginEditing(_ searchBar: UISearchBar) -> Bool {
        return true
    }
    
    func searchBarShouldEndEditing(_ searchBar: UISearchBar) -> Bool {
        return true
    }
    
}
