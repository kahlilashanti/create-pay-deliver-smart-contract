pragma solidity ^0.8.7;

//create code to ensure you have to be the owner to perform certain transactions
contract Ownable {
    address payable _owner;

    constructor() public {
        _owner = msg.sender;
    }

    modifier onlyOwner() {
        require(isOwner(), "you are not the owner");
        _;
    }

    function isOwner() public view returns (bool) {
        return (msg.sender == _owner);
    }
}

//it is better to hand off payment to a different contract to keep the logic readable and minimize
//gas fees
contract Item {
    //this contract will be responsible for taking the payment and
    //handing the payment over to the itemManager contract
    //when we create a new item we create a new instance of the itemManager using the struct
    uint256 public priceInWei;
    //check if item was paid already
    uint256 public pricePaid;
    uint256 public index;

    ItemManager parentContract;

    //we need to set these variables in the constructor
    constructor(
        ItemManager,
        _parentContract,
        uint256 _priceInWei,
        uint256 _index
    ) public {
        priceInWei = _priceInWei;
        index = _index;
        parentContract = _parentContract;
    }

    //fallback function because we are only sending money with no message data
    receive() external payable {
        require(pricePaid == 0, "Item is paid for already");
        require(priceInWei == msg.value, "only full payments allowed");
        pricePaid += msg.value;
        //low level functions are more risky because they don't throw exceptions but they do save gas
        (bool success, ) = address(parentContract).call.value(msg.value)(
            abi.encodeWithSignature("triggerPayment(uint256)", index)
        );
        //the .call method gives you two return values. a boolean for success and any return value
        //abi.encodeWithSignature creates function signatures dynamically
        //check to see if it was successful, otherwise cancel the whole transaction
        require(success, "the transaction wasn't successful. canceling...");
    }

    fallback() external {}
}

contract ItemManager is Ownable {
    //represents the state of the supply chain
    enum SupplyChainState {
        Created,
        Paid,
        Delivered
    }

    //data structure will be a struct
    struct S_Item {
        Item _item;
        string _identifier;
        uint256 _itemPrice;
        ItemManager.SupplyChainState _state;
    }

    //we need to store this item somewhere
    //store it in a data structure called items using mapping
    mapping(uint256 => S_Item) public items;
    uint256 itemIndex;

    //event to show item has been delivered
    event SupplyChainStep(
        uint256 _itemIndex,
        uint256 _step,
        address _itemAddress
    );

    function createItem(string memory _identifier, uint256 _itemPrice)
        public
        onlyOwner
    {
        Item item = new Item(this, _itemPrice, itemIndex);
        items[itemIndex]._item = item;
        items[itemIndex]._identifier = _identifier;
        items[itemIndex]._itemPrice = _itemPrice;
        items[itemIndex]._state = SupplyChainState.Created;
        //emit event here
        emit SupplyChainStep(
            itemIndex,
            uint256(items[itemIndex]._state),
            address(item)
        );
        itemIndex++;
    }

    function triggerPayment(uint256 _itemIndex) public payable {
        //accept full payments only
        require(
            items[_itemIndex]._itemPrice == msg.value,
            "Only full payments accepted"
        );
        require(
            items[_itemIndex]._state == SupplyChainState.Created,
            "Item is further in the chain"
        );
        //if you send the full value and its not paid yet...we set the item state to 'paid'
        items[_itemIndex]._state == SupplyChainState.Paid;

        //emit event here
        emit SupplyChainStep(
            _itemIndex,
            uint256(items[_itemIndex]._state),
            address(items[_itemIndex]._item)
        );
    }

    function triggerDelivery(uint256 _itemIndex) public onlyOwner {
        require(
            items[_itemIndex]._state == SupplyChainState.Paid,
            "Item is further in the chain"
        );
        //if you send the full value and its not paid yet...we set the item state to 'paid'
        items[_itemIndex]._state == SupplyChainState.Delivered;

        //emit event here
        emit SupplyChainStep(
            _itemIndex,
            uint256(items[_itemIndex]._state),
            address(items[_itemIndex]._item)
        );
    }
}
