
import UIKit
import PlaygroundSupport

class MainViewController: UIViewController {

    private let collectionViewLayout: UICollectionViewFlowLayout = {
        let layout = UICollectionViewFlowLayout()
        layout.minimumLineSpacing = 0
        layout.minimumInteritemSpacing = 0

        return layout
    }()

    private lazy var collectionView: UICollectionView = UICollectionView(frame: .zero, collectionViewLayout: collectionViewLayout)

    private let rows: Int = 32
    private let columns: Int = 32

    private var gridArray: [[UIColor]] = Array(repeating: Array(repeating: .red, count: 32), count: 32)

    override func loadView() {
        let view = UIView()
        view.backgroundColor = .white

        self.view = view
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        buildUI()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        let width = collectionView.frame.width / CGFloat(columns)
        let height = collectionView.frame.height / CGFloat(rows)

        /// Setting a static size instead of using the delegate.
        /// The delegate was being called too many times for the number of cells and hurting playground performance.
        collectionViewLayout.itemSize = CGSize(width: width, height: height)
        // If you decide to resize later, make a method to update itemSize
        collectionView.reloadData() //TODO: hide collection view before its reloaded so no flash
    }

    private func buildUI() {
        collectionView.register(UICollectionViewCell.self, forCellWithReuseIdentifier: "MyCell")
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.backgroundColor = .clear

        view.addSubview(collectionView)

        collectionView.activateConstraints([
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 5),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -5),
            collectionView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            collectionView.heightAnchor.constraint(equalTo: collectionView.widthAnchor)
        ])
    }
}

extension MainViewController: UICollectionViewDataSource {
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        rows
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        columns
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "MyCell", for: indexPath)

        cell.backgroundColor = gridArray[indexPath.row][indexPath.section]

        return cell
    }
}

extension MainViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        gridArray[indexPath.row][indexPath.section] = .blue
        collectionView.reloadItems(at: [indexPath])
        print(indexPath)
    }
}

// MARK: - Utils

extension UIView {
    func activateConstraints(_ constraints: [NSLayoutConstraint]) {
        translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate(constraints)
    }

    func pinEdges(to view: UIView) {
        translatesAutoresizingMaskIntoConstraints = false
        leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
    }
}

let vc = MainViewController()
PlaygroundPage.current.liveView = vc
