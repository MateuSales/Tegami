//
//  OnbordingViewController.swift
//  GhibliAPP
//
//  Created by Yago Marques on 08/09/22.
//

import UIKit

final class OnboardingViewController: UIViewController {

    private let viewModel: OnboardingViewModel

    init(viewModel: OnboardingViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private var counter = 0 {
        didSet {
            DispatchQueue.main.async { [weak self] in
                if let self {
                    UIView.transition(
                        with: self.nextButton,
                        duration: 0.3,
                        options: .transitionCrossDissolve,
                        animations: {
                            if self.counter == 2 {
                                self.nextButton.setTitle("Quero começar", for: .normal)
                            } else {
                                self.nextButton.setTitle("Próximo", for: .normal)
                            }
                        }
                    )
                }
            }
        }
    }

    private lazy var pageControl: UIPageControl = {
        let control = UIPageControl()
        control.translatesAutoresizingMaskIntoConstraints = false
        control.numberOfPages = 3
        control.currentPage = 0
        control.addTarget(self, action: #selector(pageControlSelectionAction), for: .primaryActionTriggered)
        control.pageIndicatorTintColor = .darkGray
        control.currentPageIndicatorTintColor = UIColor(named: "cGreen")

        return control
    }()

    private lazy var nextButton: UIButton = {
        let button = UIButton(frame: .zero)
        button.setTitle("Próximo", for: .normal)
        button.backgroundColor = UIColor(named: "cGreen")
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(toNext), for: .touchUpInside)
        button.layer.cornerRadius = 10
        button.titleLabel?.font = UIFont.systemFont(ofSize: 20, weight: .bold)

        return button
    }()

    private lazy var collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        let height = view.safeAreaLayoutGuide.layoutFrame.height
        layout.itemSize = CGSize(width: view.frame.width, height: height)
        layout.scrollDirection = .horizontal
        layout.minimumLineSpacing = 0

        let myCollectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        myCollectionView.register(OnboardingCell.self, forCellWithReuseIdentifier: "OnboardingCell")
        myCollectionView.backgroundColor = .systemGray5
        myCollectionView.isPagingEnabled = true
        myCollectionView.delegate = self
        myCollectionView.dataSource = self
        myCollectionView.translatesAutoresizingMaskIntoConstraints = false
        myCollectionView.showsHorizontalScrollIndicator = false

        return myCollectionView
    }()

    override func viewDidLoad() {
        super.viewDidLoad()

        if viewModel.onboardWasSeen() {
            navigationController?.pushViewController(MainScreenViewController(), animated: true)
        } else {
            buildLayout()
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }

    @objc func pageControlSelectionAction(_ sender: UIPageControl) {
        var indexPath: IndexPath!
        let current = pageControl.currentPage
        indexPath = IndexPath(item: current, section: 0)

        collectionView.isPagingEnabled = false
        collectionView.scrollToItem(at: indexPath, at: .centeredHorizontally, animated: true)
        collectionView.isPagingEnabled = true
    }

    func animateButton() {
        let hapticSoft = UIImpactFeedbackGenerator(style: .soft)
        let hapticRigid = UIImpactFeedbackGenerator(style: .rigid)

        hapticSoft.impactOccurred(intensity: 1.00)

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            hapticRigid.impactOccurred(intensity: 1.00)
        }

        UIView.animate(withDuration: 0.1, animations: {}, completion: { _ in
            UIView.animate(withDuration: 0.1, animations: {
                self.nextButton.layer.opacity = 0.5
            }, completion: { _ in
                UIView.animate(withDuration: 0.1, animations: {
                    self.nextButton.layer.opacity = 1
                })
            })
        })
    }

    @objc func toNext() {
        animateButton()
        var indexPath: IndexPath!
        self.pageControl.currentPage += 1
        let current = pageControl.currentPage
        indexPath = IndexPath(item: current, section: 0)
        self.counter += 1

        if self.counter <= 2 {
            collectionView.isPagingEnabled = false
            collectionView.scrollToItem(at: indexPath, at: .centeredHorizontally, animated: true)
            collectionView.isPagingEnabled = true
        } else {
            viewModel.markOnboardAsWatched()
            navigationController?.pushViewController(MainScreenViewController(), animated: true)
        }

    }
}

extension OnboardingViewController: UICollectionViewDelegate {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let scrollPos = scrollView.contentOffset.x / view.frame.width
        pageControl.currentPage = Int(scrollPos)
        self.counter = pageControl.currentPage
    }
}

extension OnboardingViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 3
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "OnboardingCell", for: indexPath) as! OnboardingCell
        cell.cellOption = indexPath.row
        cell.textContent = viewModel.textContents[indexPath.row]

        return cell
    }
}

extension OnboardingViewController: ViewCoding {
    func setupView() {
        view.backgroundColor = .systemBackground
    }

    func setupHierarchy() {
        view.addSubview(collectionView)
        view.addSubview(pageControl)
        view.addSubview(nextButton)
    }

    func setupConstraints() {
        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),

            pageControl.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            pageControl.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),

            nextButton.bottomAnchor.constraint(equalTo: pageControl.topAnchor, constant: -20),
            nextButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            nextButton.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.8),
            nextButton.heightAnchor.constraint(equalTo: nextButton.widthAnchor, multiplier: 0.2)
        ])
    }
}
