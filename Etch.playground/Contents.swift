
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

    private let cellIdentifier = String(describing: GridCell.self)
    private let gridDimension: Int = 32

    private lazy var gridArray: [[UIColor]] = Array(repeating: Array(repeating: .red, count: gridDimension), count: gridDimension)

    private var currentPosition: IndexPath = IndexPath(row: 5, section: 5)

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

        let width = collectionView.frame.width / CGFloat(gridDimension)
        let height = collectionView.frame.height / CGFloat(gridDimension)

        /// Setting a static size instead of using the delegate.
        /// The delegate was being called too many times for the number of cells and hurting playground performance.
        collectionViewLayout.itemSize = CGSize(width: width, height: height)
        // If you decide to resize later, make a method to update itemSize
        collectionView.reloadData() //TODO: hide collection view before its reloaded so no flash

        selectStartingCell()
    }

    private func buildUI() {
        collectionView.register(GridCell.self, forCellWithReuseIdentifier: cellIdentifier)
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

    private func selectStartingCell() {
        let startingIndex = currentPosition
        gridArray[startingIndex.row][startingIndex.section] = .blue
        collectionView.reloadItems(at: [startingIndex])
    }

    private func isSurroundingIndex(_ indexPath: IndexPath) -> Bool {
        let isAbove: Bool = (indexPath.section == (currentPosition.section - 1) && indexPath.row == currentPosition.row)
        let isRight: Bool = (indexPath.row == (currentPosition.row + 1) && indexPath.section == currentPosition.section)
        let isBelow: Bool = (indexPath.section == (currentPosition.section + 1) && indexPath.row == currentPosition.row)
        let isLeft: Bool = (indexPath.row == (currentPosition.row - 1) && indexPath.section == currentPosition.section)

        return isAbove || isRight || isBelow || isLeft
    }
}

extension MainViewController: UICollectionViewDataSource {
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        gridDimension
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        gridDimension
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if let cell = collectionView.dequeueReusableCell(withReuseIdentifier: cellIdentifier, for: indexPath) as? GridCell {
            cell.backgroundColor = gridArray[indexPath.row][indexPath.section]

            return cell
        }

        return UICollectionViewCell()
    }
}

extension MainViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard isSurroundingIndex(indexPath) else { return }

        gridArray[indexPath.row][indexPath.section] = .blue
        collectionView.reloadItems(at: [indexPath])

        currentPosition = indexPath
    }
}

class GridCell: UICollectionViewCell {

    override init(frame: CGRect) {
        super.init(frame: frame)
        buildUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // TODO: If needed
//    override func prepareForReuse() {
//        super.prepareForReuse()
//    }

    private func buildUI() {
        layer.borderWidth = 0.5
        layer.borderColor = UIColor.black.cgColor
        layer.cornerRadius = 2
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
