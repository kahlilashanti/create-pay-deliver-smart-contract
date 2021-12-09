pragma solidity ^0.8.7;

contract ItemManager {
    //represents the state of the supply chain
    enum SupplyChainState {
        Created,
        Paid,
        Delivered
    }

    //data structure will be a struct
    struct S_Item {
        string _identifier;
        uint256 _itemPrice;
        ItemManager.SupplyChainState _state;
    }

    //we need to store this item somewhere
    //store it in a data structure called items using mapping
    mapping(uint256 => S_Item) public items;
    uint256 itemIndex;

    //event to show item has been delivered
    event SupplyChainStep(uint256 _itemIndex, uint256 _step);

    function createItem(string memory _identifier, uint256 _itemPrice) public {
        items[itemIndex]._identifier = _identifier;
        items[itemIndex]._itemPrice = _itemPrice;
        items[itemIndex]._state = SupplyChainState.Created;
        //emit event here
        emit SupplyChainStep(itemIndex, uint256(items[itemIndex]._state));
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
        emit SupplyChainStep(_itemIndex, uint256(items[_itemIndex]._state));
    }

    function triggerDelivery(uint256 _itemIndex) public {
        require(
            items[_itemIndex]._state == SupplyChainState.Paid,
            "Item is further in the chain"
        );
        //if you send the full value and its not paid yet...we set the item state to 'paid'
        items[_itemIndex]._state == SupplyChainState.Delivered;

        //emit event here
        emit SupplyChainStep(_itemIndex, uint256(items[_itemIndex]._state));
    }
}
