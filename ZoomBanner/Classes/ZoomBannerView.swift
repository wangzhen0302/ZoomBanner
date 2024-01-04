//
//  ZoomBannerView.swift
//  ZoomBanner
//
//  Created by tzone on 2024/1/4.
//
import Foundation
import QuartzCore
import UIKit

class ZoomBannerView: UIView {
    var timer: Timer?
    private var currentPage = 0
    private var startX: CGFloat = 0
    private var endX: CGFloat = 0
    private var space: CGFloat = 40.0
    private var cellSize = CGSize(width: 200, height: 300)
    private var enlargeScale = 1.45
    private var isNeedTimer = true
    convenience init(cellSize: CGSize,enlargeScale: CGFloat,itemSpace: CGFloat, isNeedTimer: Bool = true, timerInterval: CGFloat = 3) {
        self.init()
        self.enlargeScale = enlargeScale
        self.space = (cellSize.width*enlargeScale - cellSize.width)/2 + itemSpace
        self.cellSize = cellSize
        self.isNeedTimer = isNeedTimer
        if isNeedTimer {
            self.timerInterval = timerInterval
        }

        self.addSubview(collectionView)
//        collectionView.snp.makeConstraints { make in
//            make.left.right.equalToSuperview()
//            make.top.bottom.equalToSuperview().inset(10)
//        }
    }
    private var timerInterval: CGFloat?
    func timerAction() {
        guard let cells = self.collectionView.visibleCells as? [AICollectionViewCell],var rightCell = cells.first else {
            return
        }
        for cell in cells {
            if cell.frame.origin.x > rightCell.frame.origin.x {
                rightCell = cell;
            }
        }
        guard let indexPath = self.collectionView.indexPath(for: rightCell) else { return }
        let x = CGFloat((indexPath.item-1))*(self.cellSize.width + space) + self.cellSize.width/2 - (self.frame.size.width/2 - self.cellSize.width) + space
        self.collectionView.setContentOffset(CGPoint(x: x, y: 0), animated: true)
    }
    
    deinit {
        
    }
    var items: [Any]? {
        didSet {
            self.collectionView.reloadData()
            let sp = CGFloat(self.items?.count ?? 0)*500*(self.cellSize.width + space)
            let x = sp + (self.cellSize.width/2 - self.collectionView.center.x)
            self.collectionView.setContentOffset(CGPoint(x: x, y: 0), animated: false)
            DispatchQueue.main.asyncAfter(deadline: .now()+0.1, execute: {
                self.collectionView.setContentOffset(CGPoint(x: x, y: 0), animated: true)
            })
            DispatchQueue.main.asyncAfter(deadline: .now()+0.2, execute: {
                self.collectionView.setContentOffset(CGPoint(x: x, y: 0), animated: true)
                if self.isNeedTimer {
                    self.timer?.invalidate()
                    self.timer = nil
                    
                    self.timer = Timer(timeInterval: self.timerInterval ?? 0, repeats: true, block: { [weak self] timer in
                        guard let self = self else { return }
                        self.timerAction()
                    })
                    RunLoop.current.add(self.timer!, forMode: .common)
                    self.timer?.fire()
                }
                self.scrollToIndex()
            })
           
        }
    }
    lazy var collectionView: UICollectionView = {
        let flowLayout = UICollectionViewFlowLayout()
        flowLayout.itemSize = CGSize(width: cellSize.width, height: cellSize.height)
        flowLayout.minimumLineSpacing = space
        flowLayout.minimumInteritemSpacing = 0
        flowLayout.sectionInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        flowLayout.scrollDirection = .horizontal
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: flowLayout)
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.backgroundColor = .clear
        collectionView.isPagingEnabled = true
        collectionView.clipsToBounds = false
//        collectionView.decelerationRate = .fast
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.register(AICollectionViewCell.self, forCellWithReuseIdentifier: "AICollectionViewCell")
        return collectionView
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}
extension ZoomBannerView: UICollectionViewDelegate, UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return (self.items?.count ?? 0)*1000
    }
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        
//        self.collectionView.register(AISubScriptionBannerCell.self, forCellWithReuseIdentifier: "AISubScriptionBannerCell-\(indexPath.item)")
//
//        var cell = collectionView.dequeueReusableCell(withReuseIdentifier: "AISubScriptionBannerCell-\(indexPath.item)", for: indexPath) as? AISubScriptionBannerCell
//        if cell == nil {
//            cell = AISubScriptionBannerCell()
//        }
//        guard let cell = cell else {
//            return UICollectionViewCell()
//        }
        
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "AICollectionViewCell", for: indexPath) as? AICollectionViewCell else {
            return UICollectionViewCell()
        }
//        let item = indexPath.item%(self.items?.count ?? 0)
//        guard let model = self.items?[item] as? Any else {
//            return cell
//        }
//        cell.setModel(model: model)
        return cell
    }
}
class AICollectionViewCell: UICollectionViewCell {
    
}
extension ZoomBannerView: UIScrollViewDelegate {
    
    
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        startX = scrollView.contentOffset.x
        self.timer?.fireDate = .distantFuture
    }
    func scrollViewWillEndDragging(_ scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
        
        targetContentOffset.pointee =  scrollView.contentOffset
        endX = scrollView.contentOffset.x
        
        self.scrollToIndex()
    }
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        self.timer?.fireDate = .distantPast
    }
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        for cell in self.collectionView.visibleCells {
            let centerPoint = self.convert(cell.center, from: scrollView)
            let aaa = abs(centerPoint.x - self.frame.size.width/2)
            let centerSpace = cell.contentView.bounds.size.width + space  - aaa
            let d = centerSpace/(cell.contentView.bounds.size.width + space)
            let scale = 1 + (enlargeScale - 1)*d
            cell.layer.transform = CATransform3DMakeScale(scale, scale, 1)
        }
    }
    func scrollToIndex() {
        var centerCell:UICollectionViewCell?
        var centerSpace = self.cellSize.width*3
        for cell in self.collectionView.visibleCells {
            let centerPoint = cell.convert(cell.bounds, from: self)
            let currentcenterX = (cell.frame.origin.x + centerPoint.size.width/2)
            let aaa = CGFloat(abs(currentcenterX - self.collectionView.contentOffset.x - self.frame.size.width/2))
            if centerSpace > aaa {
                centerSpace = aaa
                centerCell = cell
            }
        }
        guard let cell = centerCell else { return }
        
        let centerPoint = cell.convert(cell.bounds, from: self)
        guard let indexPath = self.collectionView.indexPath(for: cell) else { return }
        let x = CGFloat((indexPath.item))*(self.cellSize.width + space) - (self.frame.size.width/2 - self.cellSize.width/2)
        self.collectionView.setContentOffset(CGPoint(x: x, y: 0), animated: true)
    }

}



