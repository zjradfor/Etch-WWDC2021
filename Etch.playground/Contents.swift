
import UIKit
import PlaygroundSupport

class MainViewController: UIViewController {
    // MARK: Properties

    private let gridDimension: Int = 32
    private var gridArray: [[UIColor]] {
        Array(repeating: Array(repeating: .red, count: gridDimension), count: gridDimension)
    }

    private lazy var gridView: GridView = GridView(gridArray: gridArray)

    // MARK: Life Cycle Methods

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

        gridView.setUp()
    }

    // MARK: Methods

    private func buildUI() {
        view.addSubview(gridView)

        gridView.activateConstraints([
            gridView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 8),
            gridView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -8),
            gridView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            gridView.heightAnchor.constraint(equalTo: gridView.widthAnchor)
        ])
    }
}

// MARK: - GridView

class GridView: UICollectionView {
    // MARK: Properties

    private let flowLayout: UICollectionViewFlowLayout = {
        let layout = UICollectionViewFlowLayout()
        layout.minimumLineSpacing = 0
        layout.minimumInteritemSpacing = 0

        return layout
    }()

    private let cellIdentifier = String(describing: GridCell.self)

    private var currentPosition: IndexPath?

    private var gridArray: [[UIColor]]

    // MARK: Initialization

    init(gridArray: [[UIColor]]) {
        self.gridArray = gridArray
        super.init(frame: .zero, collectionViewLayout: flowLayout)

        register(GridCell.self, forCellWithReuseIdentifier: cellIdentifier)
        dataSource = self
        delegate = self
        collectionViewLayout = flowLayout
        backgroundColor = .clear
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: Public Methods

    /// Call this method when the view has loaded to get the correct frame when using constraints.
    func setUp() {
        let width = frame.width / CGFloat(gridArray.count)
        let height = frame.height / CGFloat(gridArray.count)

        flowLayout.itemSize = CGSize(width: width, height: height)
    }

    // MARK: Private Methods

    private func isSurroundingIndex(_ indexPath: IndexPath) -> Bool {
        guard let currentPos = currentPosition else { return false }

        let isAbove: Bool = indexPath == currentPos.above
        let isRight: Bool = indexPath == currentPos.right
        let isBelow: Bool = indexPath == currentPos.below
        let isLeft: Bool = indexPath == currentPos.left

        return isAbove || isRight || isBelow || isLeft
    }

    private func selectCell(_ indexPath: IndexPath) {
        guard let currentPos = currentPosition else { return }

        gridArray[indexPath.row][indexPath.section] = .blue
        reloadItems(at: [indexPath])

        if let currentCell = cellForItem(at: currentPos) as? GridCell,
           let newCell = cellForItem(at: indexPath) as? GridCell {
            currentCell.stopBlinking()
            newCell.startBlinking()
        }

//        highlightSurroundingCells(to: currentPos, selected: true)
//        highlightSurroundingCells(to: indexPath, selected: false)

        currentPosition = indexPath
    }

//    private func highlightSurroundingCells(to position: IndexPath, selected: Bool) {
//        var indexPaths: [IndexPath] = [IndexPath]()
//
//        let above = position.above
//        if above.section > 0 {
//            indexPaths.append(above)
//        }
//
//        let right = position.right
//        if right.row < gridArray.count {
//            indexPaths.append(right)
//        }
//
//        let below = position.below
//        if below.section < gridArray.count {
//            indexPaths.append(below)
//        }
//
//        let left = position.left
//        if left.row > 0 {
//            indexPaths.append(left)
//        }
//
//        indexPaths.forEach({ index in
//            if let cell = cellForItem(at: index) as? GridCell {
//                if selected {
//                    cell.startBlinking()
//                } else {
//                    cell.stopBlinking()
//                }
//            }
//        })
//        //reloadItems(at: indexPaths)
//    }
}

// MARK: - GridView Data Source

extension GridView: UICollectionViewDataSource {
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        gridArray.count
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        /// Dimensions of 2D array will always be equal so using columns again is sufficient.
        gridArray.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if let cell = collectionView.dequeueReusableCell(withReuseIdentifier: cellIdentifier, for: indexPath) as? GridCell {
            cell.backgroundColor = gridArray[indexPath.row][indexPath.section]

            return cell
        }

        return UICollectionViewCell()
    }
}

// MARK: - GridView Delegate

extension GridView: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        /// If current position is nil, set it to the tapped cell.
        guard currentPosition != nil else {
            currentPosition = indexPath
            selectCell(indexPath)
            return
        }

        guard isSurroundingIndex(indexPath) else { return }

        selectCell(indexPath)
    }
}

// MARK: - GridCell

class GridCell: UICollectionViewCell {
    // MARK: Initialization

    override init(frame: CGRect) {
        super.init(frame: frame)
        buildUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: Public Methods

    func startBlinking() {
        alpha = 0.5
        UIView.animate(withDuration: 0.5,
                       delay: 0,
                       options: [.curveEaseInOut, .autoreverse, .repeat, .allowUserInteraction]) {
            self.alpha = 1
        } completion: { _ in
            self.alpha = 0.5
        }
    }

    func stopBlinking() {
        layer.removeAllAnimations()
        alpha = 1
    }

    // MARK: Private Methods

    private func buildUI() {
        layer.borderWidth = 0.5
        layer.borderColor = UIColor.black.cgColor
        layer.cornerRadius = 2
    }
}

// MARK: - Utils

extension IndexPath {
    var above: IndexPath {
        IndexPath(row: row, section: section - 1)
    }

    var right: IndexPath {
        IndexPath(row: row + 1, section: section)
    }

    var below: IndexPath {
        IndexPath(row: row, section: section + 1)
    }

    var left: IndexPath {
        IndexPath(row: row - 1, section: section)
    }
}

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
