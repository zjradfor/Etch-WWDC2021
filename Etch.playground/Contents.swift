
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
            gridView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 5),
            gridView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -5),
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

    private var currentPosition: IndexPath = IndexPath(row: 5, section: 5)

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

        // TODO: Allow user to select starting cell
        selectStartingCell()
    }

    // MARK: Private Methods

    private func selectStartingCell() {
        let startingIndex = currentPosition
        gridArray[startingIndex.row][startingIndex.section] = .blue
    }

    private func isSurroundingIndex(_ indexPath: IndexPath) -> Bool {
        let isAbove: Bool = (indexPath.section == (currentPosition.section - 1) && indexPath.row == currentPosition.row)
        let isRight: Bool = (indexPath.row == (currentPosition.row + 1) && indexPath.section == currentPosition.section)
        let isBelow: Bool = (indexPath.section == (currentPosition.section + 1) && indexPath.row == currentPosition.row)
        let isLeft: Bool = (indexPath.row == (currentPosition.row - 1) && indexPath.section == currentPosition.section)

        return isAbove || isRight || isBelow || isLeft
    }
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
        guard isSurroundingIndex(indexPath) else { return }

        gridArray[indexPath.row][indexPath.section] = .blue
        collectionView.reloadItems(at: [indexPath])

        currentPosition = indexPath
    }
}

// MARK: - GridCell

class GridCell: UICollectionViewCell {

    override init(frame: CGRect) {
        super.init(frame: frame)
        buildUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

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
