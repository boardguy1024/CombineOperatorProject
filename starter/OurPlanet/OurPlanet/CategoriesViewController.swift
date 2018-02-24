/*
 * Copyright (c) 2016 Razeware LLC
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 */

import UIKit
import RxSwift
import RxCocoa

class CategoriesViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    let bag = DisposeBag()
    let categories = Variable<[EOCategory]>([])
    
    @IBOutlet var tableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        bind()
        startDownload()
    }
    
    private func bind() {
        categories
            .asObservable()
            .subscribe(onNext: { [weak self] _ in
                
                DispatchQueue.main.async {
                    self?.tableView.reloadData()
                }
            })
            .disposed(by: bag)
    }
    
    func startDownload() {
        // 1 처음에 categories 를 다운로드
        let eoCategories = EONET.categories
        // 2 open 이벤트 close 이벤트를 concat 해서 이벤트데이터를 다운로드
        let downloadedEvents = EONET.events(forLast: 360)
        
     
        // 3 카테고라이즈안의 카테고리 id 랑 event id 가 일치할때 그 이벤트를 카테고리.event 에 대입해서 반환함
        let updatedCategories = Observable.combineLatest(eoCategories, downloadedEvents) { (categories, events) -> [EOCategory] in
            return categories.map { category in
                var cat = category
                cat.events = events.filter {
                    $0.categories.contains(category.id)
                }
                return cat
            }
        }
        
        eoCategories
            .concat(updatedCategories)
            .bind(to: categories)
            .disposed(by: bag)
  
    }
    
    // MARK: UITableViewDataSource
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return categories.value.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "categoryCell")!
        
        let category = categories.value[indexPath.row]
        cell.textLabel?.text = "\(category.name) (\(category.events.count))"
        cell.detailTextLabel?.text = category.description
        cell.accessoryType = category.events.count > 0 ? .disclosureIndicator : .none
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        let category = categories.value[indexPath.row]
        if !category.events.isEmpty {
            let eventsController = storyboard!.instantiateViewController(withIdentifier: "events") as! EventsViewController
            
            eventsController.title = category.name
            eventsController.events.value = category.events
            navigationController?.pushViewController(eventsController, animated: true)
        }
        
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
}
















