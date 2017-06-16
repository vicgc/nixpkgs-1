#![cfg(test)]

extern crate tempdir;

use self::tempdir::TempDir;
use super::*;
use users::mock::MockUsers;
use users::{User, Group};


fn mock_users() -> (MockUsers, User) {
    let mut users = MockUsers::with_current_uid(1046);
    let johndoe = User::new(1046, "johndoe", USERS);
    users.add_group(Group::new(USERS, "users"));
    users.add_group(Group::new(SERVICE, "service"));
    users.add_user(johndoe.clone());
    users.add_user(User::new(1047, "dave", USERS));
    users.add_user(User::new(1736, "s-app", SERVICE));
    (users, johndoe)
}

#[test]
fn test_myprefix() {
    assert_eq!(myprefix(&mock_users().0).unwrap(),
               Path::new("/tmp/johndoe"));
}

#[test]
fn dont_expand_if_slashes() {
    assert_eq!(expand(Path::new("../johndoe/dir1"), Path::new("/tmp")),
               Path::new("../johndoe/dir1"))
}

#[test]
fn expand_relative() {
    assert_eq!(expand(Path::new("dir2"), Path::new("/mnt/box")),
               Path::new("/mnt/box/dir2"))
}

#[test]
fn authorized_needs_users_and_sudo_srv() {
    let (mut users, johndoe) = mock_users();
    users.add_group(Group::new(SERVICE + 1, "sudo-srv").add_member("johndoe"));
    assert!(authorized(&johndoe, &users))
}

#[test]
fn authorized_fails_without_sudo_srv() {
    let (users, johndoe) = mock_users();
    assert!(!authorized(&johndoe, &users))
}

#[test]
fn authorized_fails_wrong_primary_group() {
    let mut users = MockUsers::with_current_uid(1046);
    let johndoe = User::new(1046, "johndoe", USERS + 1);
    users.add_group(Group::new(USERS + 1, "users"));
    users.add_user(johndoe.clone());
    users.add_group(Group::new(SERVICE + 1, "sudo-srv").add_member("johndoe"));
    assert!(!authorized(&johndoe, &users))
}

#[test]
fn grant_to_service_user() {
    let users = mock_users().0;
    let tmpdir = TempDir::new("fc-box").unwrap();
    assert!(grant(tmpdir.path(), "s-app", &users).is_ok())
}

#[test]
fn grant_to_nonexistent_users_should_fail() {
    let users = mock_users().0;
    let tmpdir = TempDir::new("fc-box").unwrap();
    grant(tmpdir.path(), "nosuchuser", &users).expect_err("no error result");
}

#[test]
fn grant_to_human_users_should_fail() {
    let users = mock_users().0;
    let tmpdir = TempDir::new("fc-box").unwrap();
    grant(tmpdir.path(), "dave", &users).expect_err("no error result");
}
