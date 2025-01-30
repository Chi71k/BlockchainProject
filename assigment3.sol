// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract StudyGroups {

    event GroupCreated(address indexed creator, string groupName, uint256 groupId);
    
    event UserJoined(address indexed user, uint256 indexed groupId);

    struct StudyGroup {
        string name;
        string subject;
        address[] members;
    }

    mapping(uint256 => StudyGroup) public groups;

    uint256[] public groupIds;

    mapping(string => bool) public groupNames;

    mapping(address => uint256[]) public userGroups;

    function createGroup(string memory _name, string memory _subject) public {
        require(bytes(_name).length > 0, "Group name cannot be empty");
        require(bytes(_subject).length > 0, "Subject cannot be empty");
        require(!groupNames[_name], "Group name already exists");

        uint256 groupId = groupIds.length;
        StudyGroup storage newGroup = groups[groupId];
        newGroup.name = _name;
        newGroup.subject = _subject;
        
        groupNames[_name] = true;

        emit GroupCreated(msg.sender, _name, groupId);

        groupIds.push(groupId);
    }

    function joinGroup(uint256 _groupId) public {
        require(_groupId < groupIds.length, "Group does not exist");

        StudyGroup storage group = groups[_groupId];

        for (uint i = 0; i < group.members.length; i++) {
            require(group.members[i] != msg.sender, "You are already a member of this group");
        }

        group.members.push(msg.sender);
        userGroups[msg.sender].push(_groupId);

        emit UserJoined(msg.sender, _groupId);
    }

    function getAllGroups() public view returns (StudyGroup[] memory) {
        StudyGroup[] memory allGroups = new StudyGroup[](groupIds.length);
        for (uint256 i = 0; i < groupIds.length; i++) {
            allGroups[i] = groups[groupIds[i]];
        }
        return allGroups;
    }

    function getUserGroups(address _user) public view returns (uint256[] memory) {
        return userGroups[_user];
    }
}
