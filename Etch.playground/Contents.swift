
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

    private let menuBarView: MenuBarView = MenuBarView(frame: .zero)
    private let instructionLabel: InstructionLabel = InstructionLabel(frame: .zero)
    private lazy var gridView: GridView = GridView(gridArray: gridArray)
    private let controlView: ControlView = ControlView(frame: .zero)
    private let colourPickerView: ColourPickerView = ColourPickerView(frame: .zero)

    private let stackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.spacing = 8

        return stackView
    }()

    // MARK: Properties

    private let gridDimension: Int = 32
    private var gridArray: [[UIColor]] {
        Array(repeating: Array(repeating: Colours.brandWhite, count: gridDimension), count: gridDimension)
    }
    private var savedEtchings: [Etching] = [Etching]()

    // MARK: Life Cycle Methods

    override func loadView() {
        let view = UIView()
        view.backgroundColor = Colours.brandPink

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
        gridView.isUserInteractionEnabled = false

        DispatchQueue.main.asyncAfter(deadline: .now() + 4.5) {
            self.gridView.isUserInteractionEnabled = true
            self.instructionLabel.milestoneReached(.welcome)
            self.instructionLabel.startBlinking()
        }
    }

    // MARK: Methods

    private func buildUI() {
        menuBarView.delegate = self
        gridView.onboardingDelegate = self
        controlView.delegate = self
        colourPickerView.colourDelegate = self

        stackView.addArrangedSubview(titleLabel)
        stackView.addArrangedSubview(menuBarView)
        stackView.addArrangedSubview(instructionLabel)
        stackView.addArrangedSubview(gridView)
        stackView.addArrangedSubview(controlView)
        stackView.setCustomSpacing(16, after: controlView)
        stackView.addArrangedSubview(colourPickerView)

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

        colourPickerView.activateConstraints([
            colourPickerView.widthAnchor.constraint(equalTo: stackView.widthAnchor)
        ])
    }
}

// MARK: - MainViewController MenuBarDelegate

extension MainViewController: MenuBarDelegate {
    func didPressSave() {
        let currentGrid = gridView.getGrid()
        let newTitle = "Etching \(savedEtchings.count + 1)"
        let newEtching = Etching(title: newTitle, gridArray: currentGrid)
        savedEtchings.append(newEtching)
        menuBarView.indicateSaved()
    }

    func didPressTrash() {
        DispatchQueue.main.async {
            let alert = UIAlertController(title: "Clear Grid",
                                          message: "Are you sure?",
                                          preferredStyle: .alert)
            let cancelAction = UIAlertAction(title: "No", style: .cancel)
            let clearAction = UIAlertAction(title: "Yes", style: .default) { _ in
                self.gridView.setGrid(to: self.gridArray)
            }
            alert.addAction(cancelAction)
            alert.addAction(clearAction)

            self.present(alert, animated: true)
        }
    }

    func didPressGallery() {
        let vc = GalleryViewController(savedEtchings: savedEtchings)
        vc.galleryDelegate = self
        let nav = UINavigationController(rootViewController: vc)
        present(nav, animated: true)

        didMeetMilestone(.enjoy)
        didMeetMilestone(.gallery)
    }

    func didPressHelp() {
        print("help")
    }
}

// MARK: - MainViewController ControlDelegate

extension MainViewController: ControlDelegate {
    func didPressMoveUp() {
        gridView.moveUp()
    }

    func didPressMoveRight() {
        gridView.moveRight()
    }

    func didPressMoveDown() {
        gridView.moveDown()
    }

    func didPressMoveLeft() {
        gridView.moveLeft()
    }

    func didChangePathMagnitude(to value: Int) {
        gridView.pathMagnitude = value
        didMeetMilestone(.abstractMeter)
    }
}

// MARK: - MainViewController ColourPickerDelegate

extension MainViewController: ColourPickerDelegate {
    func didSelectColour(_ colour: UIColor) {
        controlView.setColour(to: colour)
        gridView.selectedColour = colour
        didMeetMilestone(.colour)
    }
}

// MARK: - MainViewController GalleryDelegate

extension MainViewController: GalleryDelegate {
    func loadGrid(_ gridArray: [[UIColor]]) {
        gridView.setGrid(to: gridArray)
    }
}

// MARK: - MainViewController OnboardingDelegate

extension MainViewController: OnboardingDelegate {
    func didMeetMilestone(_ milestone: InstructionLabel.Milestone) {
        guard instructionLabel.milestoneReached(milestone) else { return }

        /// Trigger next onboarding action if needed.
        switch milestone {
        case .control:
            colourPickerView.animateColourPicker()
        default:
            break
        }
    }
}

// MARK: - OnboardingDelegate

protocol OnboardingDelegate: AnyObject {
    func didMeetMilestone(_ milestone: InstructionLabel.Milestone)
}

// MARK: - InstructionLabel

class InstructionLabel: UILabel {
    // MARK: Types

    enum Milestone {
        case welcome, grid, control, colour, abstractMeter, gallery, enjoy, done

        var text: String {
            switch self {
            case .welcome: return "Welcome to Etch!"
            case .grid: return "Tap on the grid to select a starting position"
            case .control: return "Move the cursor by tapping adjacent cells or using the arrows below"
            case .colour: return "Change your colour using the Colour Picker"
            case .abstractMeter: return "Try changing the value of the Abstract Meter"
            case .gallery: return "Check out the Gallery"
            case .enjoy: return "Enjoy 😁"
            case .done: return ""
            }
        }
    }

    // MARK: Properties

    private let milestones: [Milestone] = [.welcome, .grid, .control, .colour, .abstractMeter, .gallery, .enjoy, .done]
    private var currentIndex: Int = 0

    // MARK: Initialization

    override init(frame: CGRect) {
        super.init(frame: frame)
        buildUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: Public Methods

    /// Returns true if the milestone was successfully met.
    func milestoneReached(_ milestone: Milestone) -> Bool {
        guard milestone == milestones[currentIndex],
              currentIndex + 1 < milestones.count else { return false }

        currentIndex = currentIndex + 1
        let currentMilestone = milestones[currentIndex]
        text = currentMilestone.text

        return true
    }

    // MARK: Private Methods

    private func buildUI() {
        font = .systemFont(ofSize: 10)
        textAlignment = .center
        text = milestones[currentIndex].text
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
    private let pathHelper: PathHelper = PathHelper()

    private var currentPosition: IndexPath?
    private var gridArray: [[UIColor]]

    weak var onboardingDelegate: OnboardingDelegate?

    var pathMagnitude: Int = 1

    var selectedColour: UIColor = Colours.black {
        didSet {
            /// Change the colour of cell you are currently on.
            guard let currentPos = currentPosition else { return }
            selectCells([currentPos])
        }
    }

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

    func setGrid(to array: [[UIColor]]) {
        if let currentPos = currentPosition,
           let currentCell = cellForItem(at: currentPos) as? GridCell {
            currentCell.stopBlinking()
        }

        currentPosition = nil
        gridArray = array
        reloadData()
    }

    func getGrid() -> [[UIColor]] {
        return gridArray
    }

    func moveUp() {
        guard let currentPos = currentPosition else { return }
        let path = pathHelper.generatePath(with: [currentPos.above], from: .up, magnitude: pathMagnitude)
        selectCells(path)
    }

    func moveRight() {
        guard let currentPos = currentPosition else { return }
        let path = pathHelper.generatePath(with: [currentPos.right], from: .right, magnitude: pathMagnitude)
        selectCells(path)
    }

    func moveDown() {
        guard let currentPos = currentPosition else { return }
        let path = pathHelper.generatePath(with: [currentPos.below], from: .down, magnitude: pathMagnitude)
        selectCells(path)
    }

    func moveLeft() {
        guard let currentPos = currentPosition else { return }
        let path = pathHelper.generatePath(with: [currentPos.left], from: .left, magnitude: pathMagnitude)
        selectCells(path)
    }

    // MARK: Private Methods

    private func isValidIndex(_ indexPath: IndexPath) -> Bool {
        let topValid: Bool = indexPath.section >= 0
        let rightValid: Bool = indexPath.row < gridArray.count
        let bottomValid: Bool = indexPath.section < gridArray.count
        let leftValid: Bool = indexPath.row >= 0

        return topValid && rightValid && bottomValid && leftValid
    }

    private func selectCells(_ indexPaths: [IndexPath]) {
        guard let currentPos = currentPosition else { return }

        onboardingDelegate?.didMeetMilestone(.control)

        /// Only use indexPaths within bounds of grid.
        let validIndexPaths: [IndexPath] = indexPaths.filter({ isValidIndex($0) })

        for indexPath in validIndexPaths {
            gridArray[indexPath.row][indexPath.section] = selectedColour
        }

        reloadData()

        guard let lastIndex = validIndexPaths.last else { return }

        if let currentCell = cellForItem(at: currentPos) as? GridCell,
           let newCell = cellForItem(at: lastIndex) as? GridCell {
            currentCell.stopBlinking()
            newCell.startBlinking()
        }

        currentPosition = lastIndex
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
        guard let currentPos = currentPosition else {
            currentPosition = indexPath
            selectCells([indexPath])
            onboardingDelegate?.didMeetMilestone(.grid)
            return
        }

        if indexPath == currentPos.above { moveUp() }
        if indexPath == currentPos.right { moveRight() }
        if indexPath == currentPos.below { moveDown() }
        if indexPath == currentPos.left { moveLeft() }
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

    // MARK: Methods

    private func buildUI() {
        layer.borderWidth = 0.5
        layer.borderColor = UIColor.black.cgColor
        layer.cornerRadius = 2
    }
}

// MARK: - PathHelper

class PathHelper {
    // MARK: Types

    enum Direction {
        case up, right, down, left

        var reverse: Self {
            switch self {
            case .up: return .down
            case .right: return .left
            case .down: return .up
            case .left: return .right
            }
        }

        func getIndexPath(from indexPath: IndexPath) -> IndexPath {
            switch self {
            case .up: return indexPath.above
            case .right: return indexPath.right
            case .down: return indexPath.below
            case .left: return indexPath.left
            }
        }
    }

    // MARK: Properties

    private let directions: [Direction] = [.up, .right, .down, .left]

    // MARK: Methods

    /// generate a random path recursively. magnitude = 1 is normal. NOTE: this will give magnitude - 1 values.
    func generatePath(with indexPaths: [IndexPath], from direction: Direction, magnitude: Int) -> [IndexPath] {
        var generatedPath: [IndexPath] = indexPaths

        guard magnitude > 1,
              let previousIndex = indexPaths.last else {
            return generatedPath
        }

        let allowedDirections = directions.filter({ $0 != direction.reverse })
        let randomDirection = allowedDirections.randomElement() ?? .up
        let pathValue = randomDirection.getIndexPath(from: previousIndex)
        generatedPath.append(pathValue)

        return generatePath(with: generatedPath, from: direction, magnitude: magnitude - 1)
    }
}

// MARK: - ControlButton

class ControlButton: UIButton {
    // MARK: Types

    enum ButtonType {
        case up, right, down, left, palette, trash, help, save, gallery

        var symbol: String {
            switch self {
            case .up: return "arrowtriangle.up.fill"
            case .right: return "arrowtriangle.right.fill"
            case .down: return "arrowtriangle.down.fill"
            case .left: return "arrowtriangle.left.fill"
            case .palette: return "paintpalette.fill"
            case .trash: return "trash.fill"
            case .help: return "questionmark"
            case .save: return "archivebox.fill"
            case .gallery: return "square.grid.3x3.fill"
            }
        }
    }

    // MARK: Properties

    private let type: ButtonType

    // MARK: Initialization

    init(type: ButtonType) {
        self.type = type
        super.init(frame: .zero)
        buildUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: Methods

    private func buildUI() {
        backgroundColor = Colours.brandSalmon
        layer.cornerRadius = 5
        let image = UIImage(systemName: type.symbol)
        setImage(image, for: .normal)

        tintColor = Colours.brandBrown
    }
}

// MARK: - ControlDelegate

protocol ControlDelegate: AnyObject {
    func didPressMoveUp()
    func didPressMoveRight()
    func didPressMoveDown()
    func didPressMoveLeft()
    func didChangePathMagnitude(to value: Int)
}

// MARK: - ControlView

class ControlView: UIStackView {
    // MARK: UI Elements

    private let upButton: ControlButton = ControlButton(type: .up)
    private let rightButton: ControlButton = ControlButton(type: .right)
    private let downButton: ControlButton = ControlButton(type: .down)
    private let leftButton: ControlButton = ControlButton(type: .left)

    private let colourView: UIView = {
        let view = UIView()
        view.layer.cornerRadius = 5
        view.backgroundColor = Colours.black

        return view
    }()

    private let pathControlView: PathControlView = PathControlView(frame: .zero)

    // MARK: UI Containers

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

    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: Public Methods

    func setColour(to colour: UIColor) {
        colourView.backgroundColor = colour
    }

    // MARK: Private Methods

    private func buildUI() {
        pathControlView.delegate = self

        axis = .horizontal
        spacing = 8

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

        addArrangedSubview(vertStackView)
        addArrangedSubview(pathControlView)
    }

    private func applyConstraints() {
        [upButton, rightButton, downButton, leftButton, colourView].forEach { view in
            view.activateConstraints([
                view.widthAnchor.constraint(equalToConstant: 32),
                view.heightAnchor.constraint(equalToConstant: 32)
            ])
        }

        pathControlView.activateConstraints([
            pathControlView.widthAnchor.constraint(equalToConstant: 208),
            pathControlView.heightAnchor.constraint(equalTo: heightAnchor)
        ])
    }

    // MARK: Actions

    @objc
    private func moveUpPressed() {
        delegate?.didPressMoveUp()
    }

    @objc
    private func moveRightPressed() {
        delegate?.didPressMoveRight()
    }

    @objc
    private func moveDownPressed() {
        delegate?.didPressMoveDown()
    }

    @objc
    private func moveLeftPressed() {
        delegate?.didPressMoveLeft()
    }
}

// MARK: - ControlView PathControlDelegate

extension ControlView: PathControlDelegate {
    func didChangePathMagnitude(to value: Int) {
        delegate?.didChangePathMagnitude(to: value)
    }
}

// MARK: - PathControlDelegate

protocol PathControlDelegate: AnyObject {
    func didChangePathMagnitude(to value: Int)
}

// MARK: - PathControlView

class PathControlView: UIView {
    // MARK: UI Elements

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "Abstract Meter"
        label.font = .boldSystemFont(ofSize: 16)

        return label
    }()

    private let subTitleLabel: UILabel = {
        let label = UILabel()
        label.text = "Adjusting this value will create random paths."
        label.font = .systemFont(ofSize: 8)
        label.numberOfLines = 0

        return label
    }()

    private let slider: UISlider = {
        let slider = UISlider()
        slider.tintColor = Colours.brandBrown
        slider.maximumTrackTintColor = Colours.brandPink
        slider.setThumbImage(UIImage(systemName: "die.face.1.fill"), for: .normal)
        /// Setting to false to help Playground performance.
        slider.isContinuous = false

        return slider
    }()

    private let percentageLabel: UILabel = {
        let label = UILabel()
        label.text = "0%"
        label.font = .systemFont(ofSize: 8)
        label.textAlignment = .right

        return label
    }()

    private let stackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical

        return stackView
    }()

    // MARK: Properties

    private let minValue: Int = 1
    private let maxValue: Int = 24

    weak var delegate: PathControlDelegate?

    // MARK: Initialization

    override init(frame: CGRect) {
        super.init(frame: frame)
        buildUI()
        applyConstraints()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: Methods

    private func buildUI() {
        layer.cornerRadius = 5
        backgroundColor = Colours.brandSalmon

        slider.minimumValue = Float(minValue)
        slider.maximumValue = Float(maxValue)
        slider.addTarget(self, action: #selector(sliderValueDidChange), for: .valueChanged)

        stackView.addArrangedSubview(titleLabel)
        stackView.addArrangedSubview(subTitleLabel)
        stackView.setCustomSpacing(16, after: subTitleLabel)
        stackView.addArrangedSubview(slider)
        stackView.addArrangedSubview(percentageLabel)

        addSubview(stackView)
    }

    private func applyConstraints() {
        stackView.activateConstraints([
            stackView.topAnchor.constraint(equalTo: topAnchor, constant: 8),
            stackView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -16),
            stackView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            stackView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -8)
        ])
    }

    private func setPercentageLabel(for value: Int) {
        let percentDec = Double(value - minValue) / Double(maxValue - minValue)
        let percent = Int(percentDec * 100)

        percentageLabel.text = "\(percent)%"
    }

    // MARK: Actions

    @objc
    private func sliderValueDidChange(_ sender: UISlider) {
        let value = Int(ceil(sender.value))
        setPercentageLabel(for: value)
        delegate?.didChangePathMagnitude(to: value)
    }
}

// MARK: - MenuBarDelegate

protocol MenuBarDelegate: AnyObject {
    func didPressSave()
    func didPressTrash()
    func didPressGallery()
    func didPressHelp()
}

// MARK: - MenuBarView

class MenuBarView: UIStackView {
    // MARK: UI Elements

    private let saveButton: ControlButton = ControlButton(type: .save)
    private let trashButton: ControlButton = ControlButton(type: .trash)

    private let leftStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.spacing = 8
        stackView.distribution = .equalSpacing

        return stackView
    }()

    private let galleryButton: ControlButton = ControlButton(type: .gallery)
    private let helpButton: ControlButton = ControlButton(type: .help)

    private let rightStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.spacing = 8
        stackView.distribution = .equalSpacing

        return stackView
    }()

    private let savedIndicatorLabel: UILabel = {
        let label = UILabel()
        label.text = "Saved!"
        label.font = .systemFont(ofSize: 12)
        label.alpha = 0

        return label
    }()

    // MARK: Properties

    weak var delegate: MenuBarDelegate?

    // MARK: Initialization

    override init(frame: CGRect) {
        super.init(frame: frame)
        buildUI()
        applyConstraints()
    }

    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: Public Methods

    func indicateSaved() {
        savedIndicatorLabel.alpha = 1
        UIView.animate(withDuration: 4.5,
                       delay: 1.5,
                       options: [.curveEaseInOut]) {
            self.savedIndicatorLabel.alpha = 0
        }
    }

    // MARK: Private Methods

    private func buildUI() {
        axis = .horizontal
        distribution = .equalSpacing

        saveButton.addTarget(self, action: #selector(savePressed), for: .touchUpInside)
        trashButton.addTarget(self, action: #selector(trashPressed), for: .touchUpInside)
        galleryButton.addTarget(self, action: #selector(galleryPressed), for: .touchUpInside)
        helpButton.addTarget(self, action: #selector(helpPressed), for: .touchUpInside)

        leftStackView.addArrangedSubview(saveButton)
        leftStackView.addArrangedSubview(trashButton)
        rightStackView.addArrangedSubview(galleryButton)
        rightStackView.addArrangedSubview(helpButton)

        addArrangedSubview(leftStackView)
        addArrangedSubview(savedIndicatorLabel)
        addArrangedSubview(rightStackView)
    }

    private func applyConstraints() {
        [saveButton, trashButton, galleryButton, helpButton].forEach { view in
            view.activateConstraints([
                view.widthAnchor.constraint(equalToConstant: 32),
                view.heightAnchor.constraint(equalToConstant: 32)
            ])
        }
    }

    // MARK: Actions

    @objc
    private func savePressed() {
        delegate?.didPressSave()
    }

    @objc
    private func trashPressed() {
        delegate?.didPressTrash()
    }

    @objc
    private func galleryPressed() {
        delegate?.didPressGallery()
    }

    @objc
    private func helpPressed() {
        delegate?.didPressHelp()
    }
}

// MARK: - ColourPickerDelegate

protocol ColourPickerDelegate: AnyObject {
    func didSelectColour(_ colour: UIColor)
}

// MARK: - ColourPickerView

class ColourPickerView: UIStackView {
    // MARK: UI Elements

    private let paletteButton: ControlButton = ControlButton(type: .palette)

    private lazy var collectionView: UICollectionView = {
        let view = UICollectionView(frame: .zero, collectionViewLayout: flowLayout)
        view.register(ColourCell.self, forCellWithReuseIdentifier: cellIdentifier)
        view.dataSource = self
        view.delegate = self
        view.backgroundColor = .clear
        view.showsHorizontalScrollIndicator = false

        return view
    }()

    // MARK: Properties

    private let flowLayout: UICollectionViewFlowLayout = {
        let layout = UICollectionViewFlowLayout()
        layout.minimumLineSpacing = 4
        /// Using just outside 8x scale to show half a cell at end of layout.
        layout.itemSize = CGSize(width: 34, height: 34)
        layout.scrollDirection = .horizontal

        return layout
    }()

    private let cellIdentifier = String(describing: ColourCell.self)
    private let colourArray: [UIColor] = [Colours.black, Colours.blue, Colours.red, Colours.tan,
                                          Colours.darkGreen, Colours.lightGreen, Colours.yellow, Colours.white,
                                          Colours.gray, Colours.cyan, Colours.orange, Colours.brown,
                                          Colours.pink, Colours.violet, Colours.brightGreen, Colours.magenta]
    private var selectedIndex: IndexPath = IndexPath(row: 0, section: 0)

    weak var colourDelegate: ColourPickerDelegate?

    // MARK: Initialization

    override init(frame: CGRect) {
        super.init(frame: frame)
        buildUI()
        applyConstraints()
    }

    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: Public Methods

    func animateColourPicker() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            self.collectionView.setContentOffset(CGPoint(x: 20, y: 0), animated: true)
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.3) {
            self.collectionView.setContentOffset(CGPoint(x: 0, y: 0), animated: true)
        }
    }

    // MARK: Private Methods

    private func buildUI() {
        axis = .horizontal
        spacing = 8

        addArrangedSubview(paletteButton)
        addArrangedSubview(collectionView)
    }

    private func applyConstraints() {
        paletteButton.activateConstraints([
            paletteButton.widthAnchor.constraint(equalToConstant: 32),
            paletteButton.heightAnchor.constraint(equalToConstant: 32)
        ])
    }
}

// MARK: - ColourPickerView Data Source

extension ColourPickerView: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        colourArray.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if let cell = collectionView.dequeueReusableCell(withReuseIdentifier: cellIdentifier, for: indexPath) as? ColourCell {
            cell.backgroundColor = colourArray[indexPath.row]
            cell.layer.borderWidth = indexPath == selectedIndex ? 0 : 4

            return cell
        }

        return UICollectionViewCell()
    }
}

// MARK: - ColourPickerView Delegate

extension ColourPickerView: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        colourDelegate?.didSelectColour(colourArray[indexPath.row])
        selectedIndex = indexPath
        collectionView.reloadItems(at: collectionView.indexPathsForVisibleItems)
    }
}

// MARK: - ColourCell

class ColourCell: UICollectionViewCell {
    // MARK: Initialization

    override init(frame: CGRect) {
        super.init(frame: frame)
        buildUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: Methods

    private func buildUI() {
        layer.cornerRadius = 5
        layer.borderColor = Colours.brandPink.cgColor
    }
}

// MARK: - GalleryDelegate

protocol GalleryDelegate: AnyObject {
    func loadGrid(_ gridArray: [[UIColor]])
}

// MARK: - GalleryViewController

class GalleryViewController: UICollectionViewController {
    // MARK: UI Elements

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "Gallery"
        label.font = .preferredFont(forTextStyle: .largeTitle)

        return label
    }()

    // MARK: Properties

    private let flowLayout: UICollectionViewFlowLayout = {
        let layout = UICollectionViewFlowLayout()
        layout.minimumLineSpacing = 8
        layout.sectionInset = UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8)

        return layout
    }()

    private let cellIdentifier = String(describing: GalleryCell.self)
    private let descriptionCellIdentifier = String(describing: GalleryDescriptionCell.self)

    private var etchingsArray: [Etching] = [Etching]()

    weak var galleryDelegate: GalleryDelegate?

    // MARK: Initialization

    init(savedEtchings: [Etching]) {
        super.init(collectionViewLayout: flowLayout)
        etchingsArray.append(contentsOf: savedEtchings)
        etchingsArray.append(contentsOf: CustomDesigns().array)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: Life Cycle Methods

    override func viewDidLoad() {
        super.viewDidLoad()

        buildUI()
    }

    // MARK: Methods

    private func buildUI() {
        collectionView.register(GalleryCell.self, forCellWithReuseIdentifier: cellIdentifier)
        collectionView.register(GalleryDescriptionCell.self, forCellWithReuseIdentifier: descriptionCellIdentifier)
        collectionView.backgroundColor = Colours.brandPink

        navigationController?.navigationBar.barTintColor = Colours.brandPink
        navigationItem.leftBarButtonItem = UIBarButtonItem(customView: titleLabel)
        let closeButton = UIBarButtonItem(image: UIImage(systemName: "xmark"),
                                         style: .done,
                                         target: self,
                                         action: #selector(didPressClose))
        closeButton.tintColor = Colours.brandBrown
        navigationItem.rightBarButtonItem = closeButton

    }

    // MARK: Actions

    @objc
    private func didPressClose() {
        dismiss(animated: true)
    }

    // MARK: Data Source

    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return etchingsArray.count + 1
    }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard indexPath.item != 0 else {
            if let descriptionCell = collectionView.dequeueReusableCell(withReuseIdentifier: descriptionCellIdentifier, for: indexPath) as? GalleryDescriptionCell {
                return descriptionCell
            }

            return UICollectionViewCell()
        }

        if let cell = collectionView.dequeueReusableCell(withReuseIdentifier: cellIdentifier, for: indexPath) as? GalleryCell {
            let text = etchingsArray[indexPath.item - 1].title
            cell.configure(text: text)

            return cell
        }

        return UICollectionViewCell()
    }

    // MARK: Delegate

    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard indexPath.item != 0 else { return }
        let gridArray = etchingsArray[indexPath.item - 1].gridArray
        galleryDelegate?.loadGrid(gridArray)

        dismiss(animated: true)
    }
}

// MARK: - GalleryViewController Layout

extension GalleryViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let numberOfCells: CGFloat = 3
        let cellSpacing: CGFloat = 8
        let extraSpacing: CGFloat = (cellSpacing * (numberOfCells + 2))
        let size: CGFloat = (collectionView.frame.width - extraSpacing) / numberOfCells
        return CGSize(width: size, height: size)
    }
}

// MARK: - GalleryCell

class GalleryCell: UICollectionViewCell {
    // MARK: UI Elements

    private let label: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 12)
        label.textAlignment = .center

        return label
    }()

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

    func configure(text: String) {
        label.text = text
    }

    // MARK: Private Methods

    private func buildUI() {
        backgroundColor = Colours.brandSalmon
        layer.cornerRadius = 5

        addSubview(label)
    }

    private func applyConstraints() {
        label.activateConstraints([
            label.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 8),
            label.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -8),
            label.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])
    }
}

// MARK: - GalleryDescriptionCell

class GalleryDescriptionCell: UICollectionViewCell {
    // MARK: UI Elements

    private let label: UILabel = {
        let label = UILabel()
        label.text = "Your saved Etchings will appear here. Select an Etching to load it onto the grid."
        label.font = .systemFont(ofSize: 8)
        label.numberOfLines = 0

        return label
    }()

    // MARK: Initialization

    override init(frame: CGRect) {
        super.init(frame: frame)
        buildUI()
        applyConstraints()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: Private Methods

    private func buildUI() {
        backgroundColor = Colours.brandSalmon
        layer.cornerRadius = 5
        layer.borderWidth = 1
        layer.borderColor = UIColor.black.cgColor

        addSubview(label)
    }

    private func applyConstraints() {
        label.activateConstraints([
            label.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 8),
            label.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -8),
            label.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])
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
    func startBlinking() {
        UIView.animate(withDuration: 0.5,
                       delay: 0,
                       options: [.curveEaseInOut, .autoreverse, .repeat, .allowUserInteraction]) {
            self.alpha = 0.5
        } completion: { _ in
            self.alpha = 1
        }
    }

    func stopBlinking() {
        layer.removeAllAnimations()
        alpha = 1
    }
}

extension UIView {
    func activateConstraints(_ constraints: [NSLayoutConstraint]) {
        translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate(constraints)
    }
}

let vc = MainViewController()
PlaygroundPage.current.liveView = vc
