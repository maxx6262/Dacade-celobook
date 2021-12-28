  // SPDX-License-Identifier: MIT  

pragma solidity >=0.7.0 <0.9.0;

/**
* @title Celobook
* @author mlecoustre
* @dev users can post content and give reward to posts
*   with CelobookToken which is daily distributed to user at login and signin
 */       

contract Celobook { 

        //Events
    event NewUser(address indexed _newUser,  uint _userId, string  _pseudo);
    event Reward(uint _userId, address indexed _to, uint _amount, string _type);
    event NewPost(uint _postId, address indexed _creator, string _content);
    event NewLike(uint _postId, uint _userId);
    event TransferCBT(address indexed _from, address indexed _to, uint _amount);
    event TransferPost(uint _postId, address indexed _newOwner, uint _price); 

        
        //Initial param
    uint internal postCount = 0;
    uint nbUsers = 0;
    uint internal initialBalance = 100000000;
    uint public celobookBalance = initialBalance;
        //Reward amounts
    uint newAddressReward = 10;
    uint dailyReward = 3;

        //cost of actions
    uint internal postFee = 5;
    uint internal likeFee = 1;

//         address internal celobooktokenAddress = 0;

    mapping(address => uint) internal nbPostUser;
    mapping(address => uint) internal nbLike;
    mapping(address => uint) internal userCelobookBalance;
    
    mapping(uint => Post) internal posts;
    mapping(uint => User) internal users;
    mapping(address => User) internal usersByAddress;

    //Struct of a post
    struct Post {
        uint postId;
        address payable creator;
        address payable owner;
        string content;
        uint nbLike;
        uint price;
    }
        //user Struct
    struct User {
        uint userId;
        address payable wallet;
        string pseudo;
        uint nbCreatedPost;
        uint nbOwnedPost;
        uint nbLikes;
    }

    

        //New Post function
    function writePost(string memory _content) public {
        require(userCelobookBalance[msg.sender] >= postFee, "Not enough token to perform");
        uint _postId = postCount;
        posts[_postId] = Post(_postId, 
                        payable(msg.sender), 
                        payable(msg.sender), 
                        _content, 
                        0,
                        0);
        userCelobookBalance[msg.sender] -= postFee;
        nbPostUser[msg.sender]++;
        emit NewPost(_postId, msg.sender, _content);
        postCount++;
    }

        //New User creation
    function newUserCreation(string memory _pseudo) public {
        require(!(usersByAddress[msg.sender].userId >= 0) , "User already registered");
        users[nbUsers] = User(nbUsers, payable(msg.sender), _pseudo, 0, 0, 0);
        usersByAddress[msg.sender] = users[nbUsers];
        _giveReward(payable(msg.sender), newAddressReward);
        emit Reward(nbUsers, msg.sender, newAddressReward, "User creation");
        emit NewUser(msg.sender, nbUsers, _pseudo);
        nbUsers++;
    }


        //Liking Post function
    function likePost(uint _postId) public {
        require(userCelobookBalance[msg.sender] >= likeFee, "not enough celobookToken to perform");
        require(_postId < postCount, "Post doesn't exist");
        posts[_postId].nbLike += likeFee;
        userCelobookBalance[msg.sender] -= likeFee;
        userCelobookBalance[posts[_postId].owner] += likeFee;
        emit NewLike(_postId, usersByAddress[msg.sender].userId);
    }


            //Getting informations external functions

    function getPost(uint _postId) external view returns(
        address payable _creator,
        address payable _owner,
        string memory _content,
        uint _nbLikes,
        uint price) {
        return (
            posts[_postId].creator,
            posts[_postId].owner,
            posts[_postId].content,
            posts[_postId].nbLike,
            posts[_postId].price
        );
    }

    function getContent(uint _postId) external view returns(string memory) {
        return posts[_postId].content;
    }

    function getCreator(uint _postId) external view returns(address) {
    return posts[_postId].creator;
    }

    function isBuyable(uint _postId) external view returns(bool) {
        return posts[_postId].price > 0;
    }



                //Actions on posts
    function setOnSale(uint _postId, uint _price) external  {
        require(msg.sender == posts[_postId].owner, "Only the owner can sell posts");
        require(_price > 0, "Sale price must be greater tan null");
        posts[_postId].price = _price;
    }

    function buyPost(uint _postId) external {
        require(posts[_postId].price > 0, "Post is not onSale !");
        _Transfer(msg.sender, posts[_postId].owner, posts[_postId].price);
        _TransferPost(_postId, msg.sender);
    }

                        //Private functions for safe usage

    function _giveReward(address payable _to, uint amount) private {
        require(celobookBalance >= amount, "CBT fully distributed");
        userCelobookBalance[_to] += amount;
        celobookBalance -= amount; 
    }

    function _Transfer(address _from, address _to, uint _amount) private {
        require(userCelobookBalance[_from] >= _amount, "CBT balance too low !");
        userCelobookBalance[_to] += _amount;
        userCelobookBalance[_from] -= _amount;
        emit TransferCBT(_from, _to, _amount);
    }

    function _TransferPost(uint _postId, address _newOwner) private {
        nbPostUser[posts[_postId].owner]--;
        nbPostUser[_newOwner]++;
        posts[_postId].owner = payable(_newOwner);
        emit TransferPost(_postId, _newOwner, posts[_postId].price);
        posts[_postId].price = 0;    
    }
}
