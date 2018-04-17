//
//  HomeViewController.swift
//  QueuedMusic-iPadAdmin
//
//  Created by Micky on 4/19/17.
//  Copyright © 2017 Red Shepard LLC. All rights reserved.
//

import UIKit
import CoreStore
import Whisper
import DGElasticPullToRefresh
import Spotify
import AlamofireImage
import Charts
import Darwin

protocol HomeTrackDataSourceDelegate: class {
    func dataSourceDidCompleteLoad(_ dataSource: HomeTrackDataSource, tracks: [Track]?)
}

protocol HomeTrackConfigurable {
    func configure(with track: Track?)
}

protocol HomeTrackCellConfigurable: HomeTrackConfigurable {
    var trackTitleLabel: UILabel! { get set }
    var trackArtistLabel: UILabel! { get set }
    var voteCountLabel: UILabel! { get set }
}

extension HomeTrackCellConfigurable {
    func configure(with track: Track?) {
        trackTitleLabel.text = track?.name
        trackArtistLabel.text = track?.artist
        if let voteCount = track?.voteCount {
            voteCountLabel.text = "\(voteCount)"
        }
    }
}

extension HomeTrackCell: HomeTrackCellConfigurable { }

class HomeTrackDataSource: NSObject, UITableViewDataSource {
    weak var delegate: HomeTrackDataSourceDelegate?
    var tracks: [Track] = []
    
    func load(venueId: String) {
        UIApplication.shared.isNetworkActivityIndicatorVisible = true
        QueueDataModel.shared.loadQueue(venueId: venueId) { (tracks) in
            UIApplication.shared.isNetworkActivityIndicatorVisible = false
            self.delegate?.dataSourceDidCompleteLoad(self, tracks: tracks)
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "HomeTrackCell", for: indexPath) as! HomeTrackCell
        
        let track = tracks[indexPath.item]
        (cell as HomeTrackConfigurable).configure(with: track)
        
        cell.contentView.backgroundColor = indexPath.row == 0 && track.playing! == true ? #colorLiteral(red: 0.1565925479, green: 0.1742246747, blue: 0.2227806747, alpha: 1) : #colorLiteral(red: 0.1614608765, green: 0.1948977113, blue: 0.2560786903, alpha: 1)
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.tracks.count
    }
}

class HomeViewController : UIViewController {
    
    @IBOutlet weak var trackTableView: UITableView!
    @IBOutlet weak var emptyQueueImageView: UIImageView!
    @IBOutlet weak var accountLabel: UILabel!
    @IBOutlet weak var lifetimeLabel: UILabel!
    @IBOutlet weak var pastLabel: UILabel!
    @IBOutlet weak var usersLabel: UILabel!
    @IBOutlet weak var songsLabel: UILabel!
    @IBOutlet weak var lineChartView: LineChartView!
    @IBOutlet weak var pieChartView: PieChartView!
    @IBOutlet weak var escrowChartIndividualLabel: UILabel!
    @IBOutlet weak var escrowTapView: UIView!
    @IBOutlet weak var customerTapView: UIView!
    @IBOutlet weak var escrowRefreshButton: UIButton!
    @IBOutlet weak var customerRefreshButton: UIButton!
    @IBOutlet weak var customerActivityView: UIView!
    @IBOutlet weak var customerActivityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var escrowActivityView: UIView!
    @IBOutlet weak var escrowActivityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var songActivityView: UIView!
    @IBOutlet weak var songActivityIndicator: UIActivityIndicatorView!
    
    var loadingView: DGElasticPullToRefreshLoadingViewCircle!
    var refreshing: Bool!
    
    let dataSource = HomeTrackDataSource()
    var escrowSummary: [EscrowSummary] = []
    var escrowChartSummary: [EscrowSummary] = []
    var escrowChartData: [Double] = []
    var customXAxisRenderer: CustomXAxisRenderer?
    
    var parentMainViewController: MainViewController! = nil
    
    class func instance()->UIViewController{
        let homeController = UIStoryboard(name: "Home", bundle: nil).instantiateViewController(withIdentifier: "HomeViewController")
        let nav = UINavigationController(rootViewController: homeController)
        nav.navigationBar.isTranslucent = false
        nav.navigationBar.isHidden = true
        return nav
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        dataSource.delegate = self
        trackTableView.dataSource = dataSource
        trackTableView.tableFooterView = UIView()
        
        loadingView = DGElasticPullToRefreshLoadingViewCircle()
        loadingView.tintColor = #colorLiteral(red: 0.9999966025, green: 0.9999999404, blue: 0.9999999404, alpha: 1)
        
        self.refreshing = true
        dataSource.tracks.removeAll()
        trackTableView.reloadData()
        
        self.escrowTapView.isHidden = true
        self.customerTapView.isHidden = true
        
        self.initEscrowLabel(account: "0", lifetime: "0", past: "0")
        self.initCustomersLabel(songs: "0")
        
        self.initLineChart()
        
        self.pieChartView.isHidden = true
        
        self.showEscrowActivityIndicator(show: false)
        self.showSongActivityIndicator(show: false)
        self.showCustomerActivityIndicator(show: false)
    }
    
    func initPieChart(customer: Customer) {
        self.pieChartView.delegate = self;
        
        let l = self.pieChartView.legend
        l.horizontalAlignment = Legend.HorizontalAlignment.right
        l.verticalAlignment = Legend.VerticalAlignment.top
        l.orientation = Legend.Orientation.vertical
        l.drawInside = false
        l.xEntrySpace = 0.0
        l.yEntrySpace = 0.0
        l.yOffset = 0.0
        l.enabled = false
        
        // entry label styling
        self.pieChartView.entryLabelColor = UIColor.red
        self.pieChartView.entryLabelFont = UIFont.systemFont(ofSize: 12.0)
        self.pieChartView.chartDescription?.enabled = false
        self.pieChartView.holeRadiusPercent = 0.9
        self.pieChartView.holeColor = UIColor.init(red: 107.0 / 255.0, green: 243.0 / 255.0, blue: 173.0 / 255.0, alpha: 0.0)
        
        let accountAttributes1 = [NSForegroundColorAttributeName: #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1), NSFontAttributeName: UIFont.systemFont(ofSize: 30)] as [String : Any]
        let accountAttributes2 = [NSForegroundColorAttributeName: #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1), NSFontAttributeName: UIFont.systemFont(ofSize: 11)] as [String : Any]
        
        let accountOne = NSMutableAttributedString(string: String.init(format:"  %d\n", customer.totalVotes!), attributes: accountAttributes1)
        let accountTwo = NSMutableAttributedString(string: "TOTAL VOTES", attributes: accountAttributes2)
        
        let combination = NSMutableAttributedString()
        
        combination.append(accountOne)
        combination.append(accountTwo)
        
        self.pieChartView.centerAttributedText = combination
        
        self.setPieDataCount(regularVotes: Double(customer.regularVotes!), premiumVotes: Double(customer.premiumVotes!))
        
        self.pieChartView.isHidden = false
        
        self.pieChartView.animate(xAxisDuration: 1.5)
    }
    
    func setPieDataCount(regularVotes: Double!, premiumVotes: Double!) {
        var values: [PieChartDataEntry] = []
        
        values.append(PieChartDataEntry.init(value: regularVotes))
        values.append(PieChartDataEntry.init(value: premiumVotes))
        
        let dataSet = PieChartDataSet.init(values: values, label: "")
        
        dataSet.sliceSpace = 2.0
        dataSet.xValuePosition = .outsideSlice
        dataSet.yValuePosition = .outsideSlice
        dataSet.valueLineWidth = 0.0
        // add a lot of colors
        
        var colors : [UIColor] = [];
        colors.append(UIColor.init(red: 3.0 / 255.0, green: 111.0 / 255.0, blue: 152.0 / 255.0, alpha: 1.0) )
        colors.append(UIColor.init(red: 107.0 / 255.0, green: 243.0 / 255.0, blue: 173.0 / 255.0, alpha: 1.0) )
        dataSet.colors = colors
        
        let data = PieChartData(dataSet: dataSet)
        
        let pFormatter = NumberFormatter()
        
        pFormatter.numberStyle = .none
        pFormatter.maximumFractionDigits = 1
        pFormatter.multiplier = 1
        //pFormatter.percentSymbol = " %"
        data.setValueFormatter(DefaultValueFormatter(formatter:pFormatter))
        data.setValueFont(UIFont(name: "HelveticaNeue-Light", size: 11))
        data.setValueTextColor(UIColor.white)
        
        self.pieChartView.data = data;
    }
    
    func initLineChart() {
        self.lineChartView.delegate = self;
        
        self.lineChartView.chartDescription?.enabled = false
        
        self.lineChartView.dragEnabled = false
        self.lineChartView.setScaleEnabled(false)
        self.lineChartView.pinchZoomEnabled = false
        self.lineChartView.drawGridBackgroundEnabled = false
        self.lineChartView.isMultipleTouchEnabled = false
        //self.lineChartView.highlightPerTapEnabled = false
        
        // x-axis limit line
        let llXAxis = ChartLimitLine.init(limit: 10.0, label: "Index 10")
        llXAxis.lineWidth = 4.0;
        llXAxis.lineDashLengths = [10.0, 10.0, 0.0]
        llXAxis.labelPosition = ChartLimitLine.LabelPosition.rightBottom
        llXAxis.valueFont = UIFont.systemFont(ofSize: 10.0)
        llXAxis.valueTextColor = UIColor.gray
        
        self.lineChartView.xAxis.gridLineDashLengths = [10.0, 10.0]
        self.lineChartView.xAxis.gridLineDashPhase = 0.0;
        self.lineChartView.xAxis.labelPosition = XAxis.LabelPosition.bottom
        
        let leftAxis = self.lineChartView.leftAxis
        leftAxis.removeAllLimitLines()
        leftAxis.axisMaximum = 200.0
        leftAxis.axisMinimum = 0.0
        leftAxis.gridLineDashLengths = [5.0, 5.0]
        leftAxis.drawZeroLineEnabled = false
        leftAxis.drawLimitLinesBehindDataEnabled = true
        leftAxis.labelTextColor = UIColor.gray
        self.lineChartView.xAxis.labelTextColor = UIColor.gray
        
        self.customXAxisRenderer = CustomXAxisRenderer(viewPortHandler: self.lineChartView.viewPortHandler, xAxis: self.lineChartView.xAxis, transformer: self.lineChartView.getTransformer(forAxis: .left))
        self.lineChartView.rightAxis.enabled = false
        self.lineChartView.xAxis.enabled = true
        self.lineChartView.xAxisRenderer = self.customXAxisRenderer!
        
        self.updateChartData()
        
        self.lineChartView.animate(xAxisDuration: 1.5)
        self.lineChartView.delegate = self
    }
    
    func updateChartData() {
        var values : [ChartDataEntry] = []
        
        var max: Int? = 0
        
        let date = Date()
        let calendar = Calendar.current
        let dateFormatter = DateFormatter()
        let year = calendar.component(.year, from: date)
        let month = calendar.component(.month, from: date)
        let day = calendar.component(.day, from: date)
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let today = Int((dateFormatter.date(from: "\(year)-\(month)-\(day)")?.timeIntervalSince1970)!)
        self.escrowChartData.removeAll()
        
        for k in 0..<7 {
            var dayTotal = 0
            var min = 0
            for i in 0..<self.escrowChartSummary.count
            {
                min = today - (6 - k) * 86400
                if (self.escrowChartSummary[i].created! >= min) && (self.escrowChartSummary[i].created! < (min + 86400)) {
                    dayTotal = dayTotal + self.escrowChartSummary[i].amount!
                }
            }
            
            values.append(ChartDataEntry.init(x: Double(k), y: Double(dayTotal)))
            self.escrowChartData.append(Double(dayTotal))
            
            if max! < dayTotal {
                max = dayTotal
            }
        }
        
        self.lineChartView.leftAxis.axisMaximum = Double(max! + 200)
        
        //LineChartDataSet *set1 = nil;
        var set1 : LineChartDataSet
        
        if let data = self.lineChartView.data, data.dataSetCount > 0 {
            set1 = (self.lineChartView.data?.dataSets[0] as? LineChartDataSet)!;
            set1.values = values
            self.lineChartView.data?.notifyDataChanged()
            self.lineChartView.notifyDataSetChanged()
        } else {
            set1 = LineChartDataSet.init(values: values, label: "")
            
            set1.lineDashLengths = [5.0, 2.5] //@[@5.f, @2.5f];
            set1.highlightLineDashLengths = [5.0, 2.5] // @[@5.f, @2.5f]
            set1.setColor(UIColor.gray)
            set1.setCircleColor(UIColor.gray)
            set1.lineWidth = 1.0
            set1.circleRadius = 0.0
            set1.drawCircleHoleEnabled = false
            set1.valueFont = UIFont.systemFont(ofSize: 9.0)
            set1.drawCirclesEnabled = false
            set1.drawValuesEnabled = false
            set1.formLineWidth = 0.0
            set1.formSize = 0.0
            set1.mode = LineChartDataSet.Mode.cubicBezier
            
            set1.fillAlpha = 1
            set1.fillColor = UIColor.init(red: 107.0 / 255.0, green: 243.0 / 255.0, blue: 173.0 / 255.0, alpha: 1.0) 
            set1.drawFilledEnabled = true
            
            let data = LineChartData(dataSets: [set1])
            self.lineChartView.data = data
        }
        
        self.lineChartView.animate(xAxisDuration: 1.5)
    }
    
    func initEscrowLabel(account: String!, lifetime: String!, past: String!) {
        if account != nil && account != "null" {
            let accountAttributes1 = [NSForegroundColorAttributeName: #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1), NSFontAttributeName: UIFont.systemFont(ofSize: 20)] as [String : Any]
            let accountAttributes2 = [NSForegroundColorAttributeName: #colorLiteral(red: 0.4743354321, green: 0.9497771859, blue: 0.7335880399, alpha: 1), NSFontAttributeName: UIFont.systemFont(ofSize: 20)] as [String : Any]
            
            let accountOne = NSMutableAttributedString(string: "$ ", attributes: accountAttributes1)
            let accountTwo = NSMutableAttributedString(string: String.init(format: "%.2f", Double(account)! / 100), attributes: accountAttributes2)
            
            let combination = NSMutableAttributedString()
            
            combination.append(accountOne)
            combination.append(accountTwo)
            
            self.accountLabel.attributedText = combination
        }
        
        if lifetime != nil && lifetime != "null" {
            let lifetimeAttributes1 = [NSForegroundColorAttributeName: #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1), NSFontAttributeName: UIFont.systemFont(ofSize: 23)] as [String : Any]
            let lifetimeAttributes2 = [NSForegroundColorAttributeName: #colorLiteral(red: 0.4743354321, green: 0.9497771859, blue: 0.7335880399, alpha: 1), NSFontAttributeName: UIFont.systemFont(ofSize: 28)] as [String : Any]
            
            let lifetimeOne = NSMutableAttributedString(string: "$ ", attributes: lifetimeAttributes1)
            let lifetimeTwo = NSMutableAttributedString(string: String.init(format: "%.2f", Double(lifetime)! / 100), attributes: lifetimeAttributes2)
            
            let combination2 = NSMutableAttributedString()
            
            combination2.append(lifetimeOne)
            combination2.append(lifetimeTwo)
            
            self.lifetimeLabel.attributedText = combination2
        }
        
        if past != nil && past != "null" {
            let pastAttributes1 = [NSForegroundColorAttributeName: #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1), NSFontAttributeName: UIFont.systemFont(ofSize: 20)] as [String : Any]
            let pastAttributes2 = [NSForegroundColorAttributeName: #colorLiteral(red: 0.4743354321, green: 0.9497771859, blue: 0.7335880399, alpha: 1), NSFontAttributeName: UIFont.systemFont(ofSize: 20)] as [String : Any]
            
            let pastOne = NSMutableAttributedString(string: "$ ", attributes: pastAttributes1)
            let pastTwo = NSMutableAttributedString(string: String.init(format: "%.2f", Double(past)! / 100), attributes: pastAttributes2)
            
            let combination3 = NSMutableAttributedString()
            
            combination3.append(pastOne)
            combination3.append(pastTwo)
            
            self.pastLabel.attributedText = combination3
        }
    }
    
    func loadCustomerSummary() {
        CustomerDataModel.shared.loadCustomerSummary(accountID: VenueDataModel.shared.currentVenue.venueId) { (customer, error) in
            self.showCustomerActivityIndicator(show: false)
            self.initCustomersLabel(songs: String.init(format: "%d", (customer?.songRequestsNum)!))
            self.initPieChart(customer: customer!)
        }
        
        CheckInDataModel.shared.loadCheckIns(venueId: VenueDataModel.shared.currentVenue.venueId) { (checks) in
            self.usersLabel.text = String.init(format: "%d", checks.count)
        }
    }
    
    func loadEscrowSummary() {
        if VenueDataModel.shared.currentVenue.paymentId == "" {
            self.showEscrowActivityIndicator(show: false)
            return
        }
        
        EscrowDataModel.shared.loadEscrowSummary(accountID: VenueDataModel.shared.currentVenue.paymentId) { (summary, error) in
            self.showEscrowActivityIndicator(show: false)
            
            self.escrowSummary = summary
            self.escrowChartSummary = []
            
            let currentTimeStamp = Int(NSDate().timeIntervalSince1970)
            
            var totalAmount: Int? = 0
            var past24HourAmount: Int? = 0
            for i in 0..<summary.count {
                totalAmount = totalAmount! + summary[i].amount!
                if (currentTimeStamp - summary[i].created!) < 86400 {
                    past24HourAmount = past24HourAmount! + summary[i].amount!
                }
                
                if (currentTimeStamp - summary[i].created!) < 604800 {
                    self.escrowChartSummary.append(summary[i])
                }
            }
            
            self.escrowChartSummary = self.escrowChartSummary.reversed()
            
            self.initEscrowLabel(account: nil, lifetime: String.init(format: "%d", totalAmount!), past: String.init(format: "%d", past24HourAmount!))
            
            self.updateChartData()
        }
        
        EscrowDataModel.shared.loadBalanceAmount(accountID: VenueDataModel.shared.currentVenue.paymentId) { (amount, pending, error) in
            self.initEscrowLabel(account: amount, lifetime: nil, past: nil)
        }
    }
    
    public func setParentViewController(controller: MainViewController) {
        self.parentMainViewController = controller
    }
    
    func initCustomersLabel(songs: String!) {
        self.songsLabel.text = songs
    }
    
    public func loadData() {
        if VenueDataModel.shared.currentVenue.paymentId == "" {
            self.escrowTapView.isHidden = false
            self.customerTapView.isHidden = false
            self.escrowRefreshButton.isHidden = true
            self.customerRefreshButton.isHidden = true
        } else {
            self.escrowTapView.isHidden = true
            self.customerTapView.isHidden = true
            self.escrowRefreshButton.isHidden = false
            self.customerRefreshButton.isHidden = false
        }
        
        self.refreshing = true
        self.showEscrowActivityIndicator(show: true)
        self.showSongActivityIndicator(show: true)
        self.showCustomerActivityIndicator(show: true)
        dataSource.load(venueId: VenueDataModel.shared.currentVenue.venueId)
        
        self.loadEscrowSummary()
        self.loadCustomerSummary()
    }
    
    public func reloadEscrowData() {
        if VenueDataModel.shared.currentVenue.paymentId == "" {
            self.escrowTapView.isHidden = false
            self.customerTapView.isHidden = false
            self.escrowRefreshButton.isHidden = true
            self.customerRefreshButton.isHidden = true
        } else {
            self.escrowTapView.isHidden = true
            self.customerTapView.isHidden = true
            self.escrowRefreshButton.isHidden = false
            self.customerRefreshButton.isHidden = false
        }
        
        self.showEscrowActivityIndicator(show: true)
        self.showCustomerActivityIndicator(show: true)
        
        self.loadEscrowSummary()
        self.loadCustomerSummary()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func showEscrowActivityIndicator(show: Bool) {
        if show == true {
            self.escrowActivityIndicator.startAnimating()
            self.escrowActivityView.isHidden = false
        } else {
            self.escrowActivityIndicator.stopAnimating()
            self.escrowActivityView.isHidden = true
        }
    }
    
    func showCustomerActivityIndicator(show: Bool) {
        if show == true {
            self.customerActivityIndicator.startAnimating()
            self.customerActivityView.isHidden = false
        } else {
            self.customerActivityIndicator.stopAnimating()
            self.customerActivityView.isHidden = true
        }
    }
    
    func showSongActivityIndicator(show: Bool) {
        if show == true {
            self.songActivityIndicator.startAnimating()
            self.songActivityView.isHidden = false
        } else {
            self.songActivityIndicator.stopAnimating()
            self.songActivityView.isHidden = true
        }
    }
    
    @IBAction func refreshEscrowSummary() {
        self.showEscrowActivityIndicator(show: true)
        self.escrowChartIndividualLabel.text = ""
        self.loadEscrowSummary()
    }
    
    @IBAction func refreshCustomerSummary() {
        self.showCustomerActivityIndicator(show: true)
        self.loadCustomerSummary()
    }
    
    @IBAction func back(_ sender: Any) {
        _ = navigationController?.popViewController(animated: true)
    }
    
    @IBAction func seeMoreButtonClicked(_ sender: Any) {
        parentMainViewController.gotoQueuePage()
    }
    
    @IBAction func setupEscrowClicked(_ sender: Any) {
        if let parentViewController = self.parentMainViewController {
            EscrowSetupViewController.isEscrowSetting = true
            EscrowSetupViewController.homeViewController = self
            parentViewController.performSegue(withIdentifier: "toEscrowSettingSetupController", sender: parentViewController)
        }
    }
}

extension HomeViewController : ChartViewDelegate {
    func chartValueSelected(_ chartView: ChartViewBase, entry: ChartDataEntry, highlight: Highlight) {
        let date = Date()
        let calendar = Calendar.current
        let dateFormatter = DateFormatter()
        let year = calendar.component(.year, from: date)
        let month = calendar.component(.month, from: date)
        let day = calendar.component(.day, from: date)
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let today = Int((dateFormatter.date(from: "\(year)-\(month)-\(day)")?.timeIntervalSince1970)!)
        
        let escrow = self.escrowChartData[Int(entry.x)]
        let date1 = Date(timeIntervalSince1970: TimeInterval(today - (6 - Int(entry.x)) * 86400))
        let strDate = dateFormatter.string(from: date1)
        
        self.escrowChartIndividualLabel.text = String.init(format: "%@ $%.2f", strDate, Double(escrow) / 100)
    }
    
    func chartValueNothingSelected(_ chartView: ChartViewBase) {
        
    }
}

extension HomeViewController: HomeTrackDataSourceDelegate {
    func dataSourceDidCompleteLoad(_ dataSource: HomeTrackDataSource, tracks: [Track]?) {
        if self.refreshing == true {
            var sortedTracks = tracks?.sorted(by: {
                if $0.voteCount == $1.voteCount {
                    return $0.added!.compare($1.added!) == .orderedAscending
                }
                return $0.voteCount > $1.voteCount
            })
            if dataSource.tracks.count > 0, (sortedTracks?.count)! > 0, let newTracks = sortedTracks {
                var swapPair = [Int:Int]()
                for i in 0..<newTracks.count {
                    let newTrack = newTracks[i]
                    var oldIndex = 0
                    var exists = false
                    for j in 0..<dataSource.tracks.count {
                        if newTrack.trackId == dataSource.tracks[j].trackId {
                            oldIndex = j
                            exists = true
                            break
                        }
                    }
                    if exists {
                        var newIndex = oldIndex
                        for k in oldIndex + 1..<dataSource.tracks.count {
                            if dataSource.tracks[oldIndex].voteCount < dataSource.tracks[k].voteCount {
                                newIndex = k
                            } else if dataSource.tracks[oldIndex].voteCount == dataSource.tracks[k].voteCount && dataSource.tracks[oldIndex].added!.compare(dataSource.tracks[k].added!) == .orderedDescending {
                                newIndex = k
                            }
                        }
                        if newIndex == oldIndex && oldIndex > 0 {
                            for k in (0..<oldIndex).reversed() {
                                if dataSource.tracks[oldIndex].voteCount > dataSource.tracks[k].voteCount {
                                    newIndex = k
                                } else if dataSource.tracks[oldIndex].voteCount == dataSource.tracks[k].voteCount && dataSource.tracks[oldIndex].added!.compare(dataSource.tracks[k].added!) == .orderedAscending {
                                    newIndex = k
                                }
                            }
                        }
                        if newIndex != oldIndex && swapPair[newIndex] != oldIndex {
                            UIView.animate(withDuration: 0.5, delay: 0, options: .curveEaseInOut, animations: {
                                self.trackTableView.beginUpdates()
                                self.trackTableView.moveRow(at: IndexPath(row: oldIndex, section: 0), to: IndexPath(row: newIndex, section: 0))
                                let oldTrack = dataSource.tracks.remove(at: oldIndex)
                                dataSource.tracks.insert(oldTrack, at: newIndex)
                                swapPair[oldIndex] = newIndex
                                self.trackTableView.endUpdates()
                            }, completion: nil)
                        }
                    } else {
                        UIView.animate(withDuration: 0.5, delay: 0, options: .curveEaseInOut, animations: {
                            self.trackTableView.beginUpdates()
                            self.trackTableView.insertRows(at: [IndexPath(row: dataSource.tracks.count + 1, section: 0)], with: .fade)
                            dataSource.tracks.append(newTrack)
                            self.trackTableView.endUpdates()
                        }, completion: nil)
                    }
                }
                
                for (index, track) in dataSource.tracks.enumerated() {
                    if track.playing == true {
                        dataSource.tracks.remove(at: index)
                        dataSource.tracks.insert(track, at: 0)
                        break
                    }
                }
                
                self.trackTableView.reloadData()
            } else {
                if (sortedTracks?.count)! > 5 {
                    let count = (sortedTracks?.count)!
                    for i in 0..<(count - 5) {
                        sortedTracks?.removeLast()
                    }
                }
                
                for (index, track) in (sortedTracks?.enumerated())! {
                    if track.playing == true {
                        sortedTracks?.remove(at: index)
                        sortedTracks?.insert(track, at: 0)
                        break
                    }
                }
                dataSource.tracks = sortedTracks!
                trackTableView.reloadData()
            }
            DispatchQueue.main.async {
                self.trackTableView.dg_stopLoading()
            }
            // to fix the elastic pull-to-refresh bug that doesn't disappear
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1, execute: {
                self.trackTableView.setContentOffset(.zero, animated: true)
            })
            self.refreshing = false
        } else {
            for (index, oldTrack) in dataSource.tracks.enumerated() {
                var exists = false
                for newTrack in tracks! {
                    if oldTrack.trackId == newTrack.trackId {
                        exists = true
                        oldTrack.voteCount = newTrack.voteCount
                        oldTrack.playing = newTrack.playing
                        break
                    }
                }
                if !exists {
                    dataSource.tracks.remove(at: index)
                }
            }
            for newTrack in tracks! {
                var exists = false
                for oldTrack in dataSource.tracks {
                    if newTrack.trackId == oldTrack.trackId {
                        exists = true
                        break
                    }
                }
                if !exists {
                    dataSource.tracks.append(newTrack)
                }
            }
            
            var sortedTracks = tracks?.sorted(by: {
                if $0.voteCount == $1.voteCount {
                    return $0.added!.compare($1.added!) == .orderedAscending
                }
                return $0.voteCount > $1.voteCount
            })
            
            for (index, track) in (sortedTracks?.enumerated())! {
                if track.playing == true {
                    sortedTracks?.remove(at: index)
                    sortedTracks?.insert(track, at: 0)
                    break
                }
            }
            
            dataSource.tracks = sortedTracks!
            
            trackTableView.reloadData()
        }
        
        self.showSongActivityIndicator(show: false)
        
        emptyQueueImageView.isHidden = (tracks?.count)! > 0
        if let first = dataSource.tracks.first {
            trackTableView.dg_setPullToRefreshBackgroundColor(first.playing! ? #colorLiteral(red: 0.1565925479, green: 0.1742246747, blue: 0.2227806747, alpha: 1) : #colorLiteral(red: 0.1614608765, green: 0.1948977113, blue: 0.2560786903, alpha: 1))
        }
    }
}

