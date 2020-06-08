//
//  HomeScreenTransition.swift
//  DuckDuckGo
//
//  Copyright © 2020 DuckDuckGo. All rights reserved.
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//  http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

import Core

class HomeScreenTransition: NSObject, UIViewControllerAnimatedTransitioning {
    
    // Used to hide contents of the 'from' VC when animating.
    fileprivate let solidBackground = UIView()
    // Container for the image, will clip subviews like tab switcher cell does.
    fileprivate let imageContainer = UIView()
    // Image to display as a preview.
    fileprivate let imageView = UIImageView()
    
    fileprivate let tabSwitcherViewController: TabSwitcherViewController
    
    init(tabSwitcherViewController: TabSwitcherViewController) {
        self.tabSwitcherViewController = tabSwitcherViewController
    }
    
    func prepareSubviews(using transitionContext: UIViewControllerContextTransitioning) {
        
        transitionContext.containerView.addSubview(solidBackground)

        imageContainer.clipsToBounds = true
        
        imageView.alpha = 0
        imageContainer.addSubview(imageView)
        transitionContext.containerView.addSubview(imageContainer)
    }
    
    fileprivate func tabSwitcherCellFrame(for attributes: UICollectionViewLayoutAttributes) -> CGRect {
        var targetFrame = self.tabSwitcherViewController.collectionView.convert(attributes.frame,
                                                                                to: self.tabSwitcherViewController.view)
        
        targetFrame = targetFrame.insetBy(dx: TabViewCell.Constants.cellShadowMargin,
                            dy: TabViewCell.Constants.cellShadowMargin)
        targetFrame.origin.y += TabViewCell.Constants.cellHeaderHeight
        targetFrame.size.height -= TabViewCell.Constants.cellHeaderHeight
        return targetFrame
    }
    
    fileprivate func previewFrame(for cellBounds: CGSize) -> CGRect {
        var targetFrame = CGRect(origin: .zero, size: cellBounds)
        targetFrame.origin.y -= TabViewCell.Constants.cellHeaderHeight
        targetFrame.size.height += TabViewCell.Constants.cellHeaderHeight
        return targetFrame
    }
    
    // MARK: UIViewControllerAnimatedTransitioning

    // Override - Abstract function
    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        assertionFailure("You must implement this method")
    }
    
    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return TabSwitcherTransition.Constants.duration
    }
}

class FromHomeScreenTransition: HomeScreenTransition {
    
    private let mainViewController: MainViewController
    
    init(mainViewController: MainViewController,
         tabSwitcherViewController: TabSwitcherViewController) {
        self.mainViewController = mainViewController

        super.init(tabSwitcherViewController: tabSwitcherViewController)
    }
    
    private func makeSnapshot(of homeScreen: HomeViewController) -> UIView {
        let viewToSnapshot: UIView
        if homeScreen.logo.isHidden {
            viewToSnapshot = homeScreen.collectionView
        } else {
            viewToSnapshot = homeScreen.logoContainer
        }
        
        return viewToSnapshot.snapshotView(afterScreenUpdates: false)!
    }
    
    override func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        prepareSubviews(using: transitionContext)
        tabSwitcherViewController.prepareForPresentation()
        
        guard let homeScreen = mainViewController.homeController,
            let tab = mainViewController.currentTab?.tabModel,
        let rowIndex = tabSwitcherViewController.tabsModel.indexOf(tab: tab),
        let layoutAttr = tabSwitcherViewController.collectionView.layoutAttributesForItem(at: IndexPath(row: rowIndex, section: 0))
            else { return }
        let theme = ThemeManager.shared.currentTheme
        
        solidBackground.frame = homeScreen.view.convert(homeScreen.collectionView.frame, to: nil)
        solidBackground.backgroundColor = theme.backgroundColor
        imageContainer.frame = solidBackground.frame
        imageContainer.backgroundColor = theme.backgroundColor
        
        tabSwitcherViewController.view.alpha = 0
        transitionContext.containerView.insertSubview(tabSwitcherViewController.view, belowSubview: imageContainer)
        tabSwitcherViewController.view.frame = transitionContext.finalFrame(for: tabSwitcherViewController)
        
        let snapshot = makeSnapshot(of: homeScreen)
        snapshot.frame = CGRect(origin: .zero, size: imageContainer.bounds.size)
        imageContainer.addSubview(snapshot)
        
        imageView.frame = snapshot.frame
        imageView.contentMode = .center
        imageView.image = TabViewCell.logoImage
        
        UIView.animateKeyframes(withDuration: TabSwitcherTransition.Constants.duration, delay: 0, options: .calculationModeLinear, animations: {
            
            UIView.addKeyframe(withRelativeStartTime: 0, relativeDuration: 1.0) {
                let theme = ThemeManager.shared.currentTheme
                
                let containerFrame = self.tabSwitcherCellFrame(for: layoutAttr)
                self.imageContainer.frame = containerFrame
                self.imageContainer.layer.cornerRadius = TabViewCell.Constants.cellCornerRadius
                self.imageContainer.backgroundColor = theme.tabSwitcherCellBackgroundColor
                self.imageView.frame = self.previewFrame(for: self.imageContainer.bounds.size)
                snapshot.center = CGPoint(x: containerFrame.width / 2, y: containerFrame.height / 2)
            }
            
            UIView.addKeyframe(withRelativeStartTime: 0, relativeDuration: 0.3) {
                snapshot.alpha = 0
            }
            
            UIView.addKeyframe(withRelativeStartTime: 0.3, relativeDuration: 0.7) {
                self.tabSwitcherViewController.view.alpha = 1
            }
            
            UIView.addKeyframe(withRelativeStartTime: 0.6, relativeDuration: 0.3) {
                self.imageView.alpha = 1
            }

        }, completion: { _ in
            self.solidBackground.removeFromSuperview()
            self.imageContainer.removeFromSuperview()
            transitionContext.completeTransition(true)
        })
    }
}

class ToHomeScreenTransition: HomeScreenTransition {

    override func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        prepareSubviews(using: transitionContext)
        
        guard let mainViewController = transitionContext.viewController(forKey: .to) as? MainViewController,
            let homeScreen = mainViewController.homeController,
            let tab = mainViewController.currentTab?.tabModel,
            let rowIndex = tabSwitcherViewController.tabsModel.indexOf(tab: tab),
            let layoutAttr = tabSwitcherViewController.collectionView.layoutAttributesForItem(at: IndexPath(row: rowIndex, section: 0))
            else {
                return
        }
        
        mainViewController.view.alpha = 1
        
        let theme = ThemeManager.shared.currentTheme
        imageContainer.frame = tabSwitcherCellFrame(for: layoutAttr)
        imageContainer.backgroundColor = theme.tabSwitcherCellBackgroundColor
        imageContainer.layer.cornerRadius = TabViewCell.Constants.cellCornerRadius
        
        let snapshot = homeScreen.view.snapshotView(afterScreenUpdates: false)!
        snapshot.alpha = 0
        imageContainer.addSubview(snapshot)
        snapshot.center = CGPoint(x: imageContainer.bounds.midX, y: imageContainer.bounds.midY)
        
        imageView.frame = previewFrame(for: imageContainer.bounds.size)
        imageView.contentMode = .center
        imageView.image = TabViewCell.logoImage
        imageView.backgroundColor = .clear
        
        scrollIfOutsideViewport(collectionView: tabSwitcherViewController.collectionView, rowIndex: rowIndex, attributes: layoutAttr)
        
        UIView.animateKeyframes(withDuration: TabSwitcherTransition.Constants.duration, delay: 0, options: .calculationModeLinear, animations: {
            
            UIView.addKeyframe(withRelativeStartTime: 0, relativeDuration: 1.0) {
                self.imageContainer.frame = homeScreen.view.convert(homeScreen.collectionView.frame, to: nil)
                self.imageContainer.layer.cornerRadius = 0
                self.imageContainer.backgroundColor = theme.backgroundColor
                self.imageView.frame = CGRect(origin: .zero,
                                              size: self.imageContainer.bounds.size)
                snapshot.center = CGPoint(x: self.imageContainer.bounds.midX, y: self.imageContainer.bounds.midY)
            }
            
            UIView.addKeyframe(withRelativeStartTime: 0.0, relativeDuration: 0.3) {
                self.imageView.alpha = 0
            }
            
            UIView.addKeyframe(withRelativeStartTime: 0.5, relativeDuration: 0.3) {
                snapshot.alpha = 1
            }
            
            UIView.addKeyframe(withRelativeStartTime: 0.7, relativeDuration: 0.3) {
                self.tabSwitcherViewController.view.alpha = 0
            }
            
        }, completion: { _ in
            self.imageContainer.removeFromSuperview()
            transitionContext.completeTransition(true)
        })
    }
    // swiftlint:enable function_body_length
    
    private func scrollIfOutsideViewport(collectionView: UICollectionView,
                                         rowIndex: Int,
                                         attributes: UICollectionViewLayoutAttributes) {
        // If cell is outside viewport, scroll while animating
        let collectionView = tabSwitcherViewController.collectionView!
        if attributes.frame.origin.y + attributes.frame.size.height < collectionView.contentOffset.y {
            collectionView.scrollToItem(at: IndexPath(row: rowIndex, section: 0),
                                        at: .top,
                                        animated: true)
        } else if attributes.frame.origin.y > collectionView.frame.height + collectionView.contentOffset.y {
            collectionView.scrollToItem(at: IndexPath(row: rowIndex, section: 0),
                                        at: .bottom,
                                        animated: true)
        }
    }
}