
import UIKit
import PlaygroundSupport

class MainViewController: UIViewController {
    // MARK: UI Elements

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "Etch"
        label.font = .preferredFont(forTextStyle: .largeTitle)

        return label
    }()

    private lazy var gridView: GridView = GridView(gridArray: gridArray)

    private let controlView: ControlView = ControlView(frame: .zero)

    private let stackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.spacing = 16
        stackView.distribution = .equalSpacing

        return stackView
    }()

    // MARK: Properties

    private let gridDimension: Int = 32
    private var gridArray: [[UIColor]] {
        Array(repeating: Array(repeating: .red, count: gridDimension), count: gridDimension)
    }

    // MARK: Life Cycle Methods

    override func loadView() {
        let view = UIView()
        view.backgroundColor = .white

        self.view = view
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        buildUI()
        applyConstraints()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        gridView.setUp()
    }

    // MARK: Methods

    private func buildUI() {
        stackView.addArrangedSubview(titleLabel)
        stackView.addArrangedSubview(gridView)
        stackView.addArrangedSubview(controlView)

        view.addSubview(stackView)
    }

    private func applyConstraints() {
        stackView.activateConstraints([
            stackView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 8),
            stackView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -8),
            stackView.topAnchor.constraint(equalTo: view.topAnchor, constant: 16)
        ])

        gridView.activateConstraints([
            gridView.widthAnchor.constraint(equalTo: stackView.widthAnchor),
            gridView.heightAnchor.constraint(equalTo: gridView.widthAnchor)
        ])

        /// Frame height was not being set properly so using constant.
        controlView.activateConstraints([
            controlView.heightAnchor.constraint(equalToConstant: 112)
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

        currentPosition = indexPath
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

final class GridCell: UICollectionViewCell {
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

// MARK: ControlButton

final class ControlButton: UIButton {
    // MARK: Types

    enum Direction {
        case up, right, down, left

        var symbol: String {
            switch self {
            case .up: return "arrowtriangle.up.fill"
            case .right: return "arrowtriangle.right.fill"
            case .down: return "arrowtriangle.down.fill"
            case .left: return "arrowtriangle.left.fill"
            }
        }
    }

    // MARK: Properties

    private let direction: Direction

    // MARK: Initialization

    init(direction: Direction) {
        self.direction = direction
        super.init(frame: .zero)

        buildUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: Methods

    private func buildUI() {
        backgroundColor = .gray
        layer.cornerRadius = 5
        let image = UIImage(systemName: direction.symbol)
        setImage(image, for: .normal)
    }
}

// MARK: - ControlDelegate

protocol ControlDelegate: AnyObject {
    func didPressMoveUp()
    func didPressMoveRight()
    func didPressMoveDown()
    func didPressMoveLeft()
}

// MARK: ControlView

class ControlView: UIView {
    // MARK: UI Elements

    private let upButton: ControlButton = ControlButton(direction: .up)
    private let rightButton: ControlButton = ControlButton(direction: .right)
    private let downButton: ControlButton = ControlButton(direction: .down)
    private let leftButton: ControlButton = ControlButton(direction: .left)

    private let colourView: UIView = {
        let view = UIView()
        view.layer.cornerRadius = 5
        view.backgroundColor = .red

        return view
    }()

    private let horizStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.spacing = 8
        stackView.distribution = .fillProportionally
        stackView.translatesAutoresizingMaskIntoConstraints = false

        return stackView
    }()

    private let vertStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.spacing = 8
        stackView.alignment = .center
        stackView.translatesAutoresizingMaskIntoConstraints = false

        return stackView
    }()

    // MARK: Properties

    weak var delegate: ControlDelegate?

    // MARK: Initialization

    override init(frame: CGRect) {
        super.init(frame: frame)
        buildUI()
        applyConstraints()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: Public Methods

    func setColour(to colour: UIColor) {
        // TODO: Change middle colour depending on colour picker
    }

    // MARK: Private Methods

    private func buildUI() {
        upButton.addTarget(self, action: #selector(moveUpPressed), for: .touchUpInside)
        rightButton.addTarget(self, action: #selector(moveRightPressed), for: .touchUpInside)
        downButton.addTarget(self, action: #selector(moveDownPressed), for: .touchUpInside)
        leftButton.addTarget(self, action: #selector(moveLeftPressed), for: .touchUpInside)

        vertStackView.addArrangedSubview(upButton)

        horizStackView.addArrangedSubview(leftButton)
        horizStackView.addArrangedSubview(colourView)
        horizStackView.addArrangedSubview(rightButton)

        vertStackView.addArrangedSubview(horizStackView)
        vertStackView.addArrangedSubview(downButton)

        addSubview(vertStackView)
    }

    private func applyConstraints() {
        [upButton, rightButton, downButton, leftButton, colourView].forEach { view in
            view.activateConstraints([
                view.widthAnchor.constraint(equalToConstant: 32),
                view.heightAnchor.constraint(equalToConstant: 32)
            ])
        }
    }

    // MARK: Actions

    @objc
    private func moveUpPressed() {
        print("up")
        delegate?.didPressMoveUp()
    }

    @objc
    private func moveRightPressed() {
        print("right")
        delegate?.didPressMoveRight()
    }

    @objc
    private func moveDownPressed() {
        print("down")
        delegate?.didPressMoveDown()
    }

    @objc
    private func moveLeftPressed() {
        print("left")
        delegate?.didPressMoveLeft()
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
