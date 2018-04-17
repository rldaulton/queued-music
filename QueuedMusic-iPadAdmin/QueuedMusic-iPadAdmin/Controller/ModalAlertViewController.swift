//
//  ModalAlertViewController.swift
//  QueuedMusic
//
//  Created by Micky on 2/6/17.
//  Copyright © 2017 Red Shepard LLC. All rights reserved.
//

import UIKit

class ModalAlertViewController: UIViewController, UIViewControllerTransitioningDelegate {
    private var containedController: UIViewController?
    
    private var centerYOffset: CGFloat?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow(_:)), name: .UIKeyboardWillShow, object: view.window)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide(_:)), name: .UIKeyboardWillHide, object: view.window)
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        let touchPoint = touches.first!
        guard let containedController = containedController, touchPoint.view != containedController.view else { return }
        view.endEditing(true)
    }
    
    func set(viewController controller: UIViewController, centerYOffset: CGFloat) {
        var shouldAnimateNewView = false
        if let oldController = containedController {
            removeOldController(controller: oldController)
            shouldAnimateNewView = true
        }
        
        let sView = controller.view!
        addChildViewController(controller)
        sView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(sView)
        controller.didMove(toParentViewController: self)
        
        containedController = controller
        self.centerYOffset = centerYOffset
        let centerYConstraint = sView.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        if shouldAnimateNewView == true {
            centerYConstraint.constant = -view.frame.size.height
        }
        
        NSLayoutConstraint.activate([
            centerYConstraint,
            sView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 130),
            view.trailingAnchor.constraint(equalTo: sView.trailingAnchor, constant: 130)
            ])
        
        view.layoutIfNeeded()
        
        UIView.animate(withDuration: 0.35, delay: 0.1, options: .curveEaseOut, animations: {
            centerYConstraint.constant = centerYOffset
            self.view.layoutIfNeeded()
        }, completion: nil)
    }
    
    private func removeOldController(controller: UIViewController) {
        containedController = nil
        let oldView = controller.view!
        let center = oldView.constraintsAffectingLayout(for: .vertical).filter({ $0.firstAttribute == .centerY }).first!
        UIView.animate(withDuration: 0.35, delay: 0.0, options: .curveEaseIn, animations: {
            center.constant = self.view.frame.height + oldView.frame.size.height/2
            self.view.layoutIfNeeded()
        }) { (complete) in
            controller.willMove(toParentViewController: nil)
            oldView.removeFromSuperview()
            controller.removeFromParentViewController()
        }
    }
    
    func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return ModalTransition()
    }
    
    func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return ModalDismissTransition()
    }
    
    override var animationView: UIView { return containedController?.animationView ?? view }
    
    func keyboardWillShow(_ notification: Notification) {
        // guard let keyboardEndFrame = notification.userInfo?[UIKeyboardFrameEndUserInfoKey] as? NSValue,
        guard let animationDuration = notification.userInfo?[UIKeyboardAnimationDurationUserInfoKey] as? NSNumber,
            let animationCurve = notification.userInfo?[UIKeyboardAnimationCurveUserInfoKey] as? NSNumber,
            let containedController = containedController else {
                return
        }
        // let height = keyboardEndFrame.cgRectValue.size.height
        
        let center = containedController.view.constraintsAffectingLayout(for: .vertical).filter({ $0.firstAttribute == .centerY }).first!
        UIView.animate(withDuration: animationDuration.doubleValue, delay: 0.0, options: UIViewAnimationOptions(rawValue: animationCurve.uintValue), animations: {
            center.constant = 0 //-height
            self.view.layoutIfNeeded()
        }, completion: nil)
        
    }
    
    func keyboardWillHide(_ notification: Notification) {
        guard let containedController = containedController,
            let animationDuration = notification.userInfo?[UIKeyboardAnimationDurationUserInfoKey] as? NSNumber,
            let animationCurve = notification.userInfo?[UIKeyboardAnimationCurveUserInfoKey] as? NSNumber else { return }
        
        let center = containedController.view.constraintsAffectingLayout(for: .vertical).filter({ $0.firstAttribute == .centerY }).first!
        UIView.animate(withDuration: animationDuration.doubleValue, delay: 0.0, options: UIViewAnimationOptions(rawValue: animationCurve.uintValue), animations: {
            center.constant = 0
            self.view.layoutIfNeeded()
        }, completion: nil)
    }
    
}

extension UIViewController {
    func present(customModalViewController controller: UIViewController, centerYOffset: CGFloat) {
        let modalController: ModalAlertViewController
        if let parentModalController = parent as? ModalAlertViewController {
            modalController = parentModalController
        }
        else {
            modalController = ModalAlertViewController()
        }
        modalController.set(viewController: controller, centerYOffset: centerYOffset)
        modalController.transitioningDelegate = modalController
        
        if modalController.presentingViewController == nil {
            showDetailViewController(modalController, sender: self)
        }
    }
}

protocol ModalAnimatable {
    var animationView: UIView { get }
}

extension UIViewController: ModalAnimatable {
    var animationView: UIView { return view }
}

class ModalTransition: NSObject, UIViewControllerAnimatedTransitioning {
    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return 0.25
    }
    
    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        let fromController = transitionContext.viewController(forKey: UITransitionContextViewControllerKey.from)!
        let toController = transitionContext.viewController(forKey: UITransitionContextViewControllerKey.to)!
        let containerView = transitionContext.containerView
        
        let baseView = fromController.view!
        
        UIGraphicsBeginImageContextWithOptions(baseView.bounds.size, true, 0)
        baseView.drawHierarchy(in: baseView.bounds, afterScreenUpdates: false)
        let snapshotImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        let snapshotView = UIImageView(frame: baseView.bounds)
        snapshotView.image = snapshotImage
        snapshotView.alpha = 0.6
        
        let snap = snapshotView//fromController.view.snapshotView(afterScreenUpdates: true)
        toController.view.insertSubview(snap, at: 0)
        toController.view.alpha = 1.0
//        toController.view.backgroundColor = UIColor.white.withAlphaComponent(0.0)
        toController.view.backgroundColor = UIColor.white
        containerView.addSubview(toController.view)
        
        let toAnimatedView = toController.animationView
        toAnimatedView.alpha = 0.4
        toAnimatedView.transform = CGAffineTransform(scaleX: 0.8, y: 0.8)
        toAnimatedView.layer.cornerRadius = 4
        
        UIView.animate(withDuration: transitionDuration(using: transitionContext), delay: 0.05, usingSpringWithDamping: 0.3, initialSpringVelocity: 0.65, options: [], animations: {
            toAnimatedView.alpha = 1.0
            toAnimatedView.transform = CGAffineTransform.identity
//            snap?.alpha = 0.6
            toAnimatedView.layer.shadowOffset = CGSize(width: 0, height: 0)
            toAnimatedView.layer.shadowRadius = 6
            toAnimatedView.layer.shadowColor = UIColor.darkGray.cgColor
            toAnimatedView.layer.shadowOpacity = 0.8
        }, completion: { _ in
//            toController.view.backgroundColor = UIColor.darkGray.withAlphaComponent(1.0)
            transitionContext.completeTransition(true)
        })
    }
}

class ModalDismissTransition: NSObject, UIViewControllerAnimatedTransitioning {
    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return 0.25
    }
    
    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        let fromController = transitionContext.viewController(forKey: UITransitionContextViewControllerKey.from)!
        let toController = transitionContext.viewController(forKey: UITransitionContextViewControllerKey.to)!
        let containerView = transitionContext.containerView
        toController.view.alpha = 0.0
        let fromAnimatedView = fromController.animationView
        containerView.addSubview(toController.view)
        containerView.addSubview(fromController.view)
        
        
        
        UIView.animate(withDuration: transitionDuration(using: transitionContext), animations: {
            toController.view.alpha = 1.0
            fromAnimatedView.alpha = 0.0
            fromController.view.backgroundColor = UIColor.white.withAlphaComponent(0.0)
        }, completion: { _ in
            transitionContext.completeTransition(true)
        })
    }
}
