// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract StudyGroups {

    event GroupCreated(address indexed creator, string groupName, uint256 groupId);
    event UserJoined(address indexed user, uint256 indexed groupId, string nickname);
    event GroupDeleted(uint256 groupId);
    event UserRemoved(address indexed user, uint256 groupId);

    struct StudyGroup {
        uint256 id;               
        string name;
        string subject;
        address creator;
        address[] members;
        string[] memberNicknames;
        uint256 maxMembers;
        bool exists;
    }

    mapping(uint256 => StudyGroup) private groups;
    uint256 private nextGroupId = 0;
    mapping(string => bool) private groupNames;
    mapping(address => uint256[]) private userGroups;
    mapping(uint256 => mapping(address => bool)) private removedUsers; // Tracks removed users per group
    uint256[] private allGroupIds;

    modifier onlyGroupCreator(uint256 groupId) {
        require(groups[groupId].exists, "Group does not exist");
        require(groups[groupId].creator == msg.sender, "Only the group creator can perform this action.");
        _;
    }

    function createGroup(string memory _name, string memory _subject, uint256 _maxMembers) public {
        require(bytes(_name).length > 0, "Group name cannot be empty");
        require(bytes(_subject).length > 0, "Group subject cannot be empty");
        require(!groupNames[_name], "Group name already exists");
        require(_maxMembers > 1, "Max members must be greater than 1");
        require(_maxMembers <= 100, "Group cannot have more than 100 members");
        require(userGroups[msg.sender].length < _maxMembers, "You have already joined this group");


        uint256 groupId = nextGroupId++;
        StudyGroup storage newGroup = groups[groupId];
        newGroup.id = groupId;          
        newGroup.name = _name;
        newGroup.subject = _subject;
        newGroup.creator = msg.sender;
        newGroup.maxMembers = _maxMembers;
        newGroup.exists = true;

        groupNames[_name] = true;
        allGroupIds.push(groupId);

        emit GroupCreated(msg.sender, _name, groupId);
    }

    function joinGroup(uint256 _groupId, string memory _nickname) public {
        require(groups[_groupId].exists, "Group does not exist");
        
        // Separate checks for empty nickname and long nickname
        require(bytes(_nickname).length > 0, "Nickname cannot be empty");
        require(bytes(_nickname).length <= 15, "Nickname way is too long");


        StudyGroup storage group = groups[_groupId];

        // Check if the user has been removed from the group before
        require(!removedUsers[_groupId][msg.sender], "You have been removed from this group and cannot rejoin");

        require(group.members.length < group.maxMembers, "Group is full");

        // Check if the user is already a member
        for (uint256 i = 0; i < group.members.length; i++) {
            if (group.members[i] == msg.sender) {
                revert("You are already a member of this group");
            }
        }

        // Check if the nickname is already taken
        for (uint256 i = 0; i < group.memberNicknames.length; i++) {
            if (keccak256(abi.encodePacked(group.memberNicknames[i])) == keccak256(abi.encodePacked(_nickname))) {
                revert("Nickname already taken");
            }
        }

        group.members.push(msg.sender);
        group.memberNicknames.push(_nickname);
        userGroups[msg.sender].push(_groupId);

        emit UserJoined(msg.sender, _groupId, _nickname);
    }


    function deleteGroup(uint256 _groupId) public onlyGroupCreator(_groupId) {
        StudyGroup storage group = groups[_groupId];
        require(group.exists, "Group does not exist");

        // Delete group and clean up mappings
        groupNames[group.name] = false;
        delete groups[_groupId];

        // Remove from allGroupIds
        uint256 i;
        for (i = 0; i < allGroupIds.length; i++) {
            if (allGroupIds[i] == _groupId) {
                allGroupIds[i] = allGroupIds[allGroupIds.length - 1];
                allGroupIds.pop();
                break;
            }
        }

        emit GroupDeleted(_groupId);
    }

    function removeUser(uint256 _groupId, address _user) public onlyGroupCreator(_groupId) {
        StudyGroup storage group = groups[_groupId];
        bool userFound = false;
        uint256 userIndex;

        for (uint256 i = 0; i < group.members.length; i++) {
            if (group.members[i] == _user) {
                userFound = true;
                userIndex = i;
                break;
            }
        }

        require(userFound, "User is not a member of the group");

        group.members[userIndex] = group.members[group.members.length - 1];
        group.memberNicknames[userIndex] = group.memberNicknames[group.memberNicknames.length - 1];
        group.members.pop();
        group.memberNicknames.pop();

        // Mark the user as removed from the group
        removedUsers[_groupId][_user] = true;

        for (uint256 i = 0; i < userGroups[_user].length; i++) {
            if (userGroups[_user][i] == _groupId) {
                userGroups[_user][i] = userGroups[_user][userGroups[_user].length - 1];
                userGroups[_user].pop();
                break;
            }
        }

        emit UserRemoved(_user, _groupId);
    }

    function getAllGroups() public view returns (StudyGroup[] memory) {
        uint256 count = allGroupIds.length;
        StudyGroup[] memory activeGroups = new StudyGroup[](count);

        for (uint256 i = 0; i < count; i++) {
            uint256 groupId = allGroupIds[i];
            if (groups[groupId].exists) {
                activeGroups[i] = groups[groupId];
            }
        }

        return activeGroups;
    }

    function getUserGroups(address _user) public view returns (uint256[] memory) {
        return userGroups[_user];
    }

    function getGroupInfo(uint256 _groupId) 
        public 
        view 
        returns (
            uint256 groupId,             
            string memory name, 
            string memory subject, 
            address[] memory members, 
            string[] memory memberNicknames, 
            address creator, 
            uint256 maxMembers
        ) 
    {
        require(groups[_groupId].exists, "Group does not exist");
        StudyGroup storage group = groups[_groupId];
        return (group.id, group.name, group.subject, group.members, group.memberNicknames, group.creator, group.maxMembers);
    }
}
