use std::{fs, path::Path};

use git2::{Error, ErrorClass, ErrorCode, Repository};

pub mod models;
pub mod services;

pub fn open_repo_chase_workspace<P: AsRef<Path>>(dir: P) -> Result<Repository, Error> {
    let dir = dir.as_ref();
    if let Ok(repo) = Repository::open(dir) {
        return Ok(repo);
    }

    let jj_repo_file_path = dir.join(".jj/repo");
    let file_content = fs::read_to_string(&jj_repo_file_path).map_err(|_| {
        Error::new(
            ErrorCode::GenericError,
            ErrorClass::Repository,
            "Directory is neither a git repository nor a valid jj workspace",
        )
    })?;

    // In secondary jj workspaces, `.jj/repo` contains a relative path
    // pointing back to the root workspace's `.jj/repo` folder.
    let rel_target = file_content.trim().trim_end_matches(".jj/repo");
    let root_workspace = dir.join(".jj").join(rel_target);

    Repository::open(root_workspace)
}

#[cfg(test)]
mod tests {
    use super::*;
    use tempfile::TempDir;
    use test_repo::TestRepo;

    #[test]
    fn can_open_root_workspace() {
        let t_repo = TestRepo::new().unwrap();
        let repo = open_repo_chase_workspace(t_repo.path()).unwrap();
        assert_eq!(t_repo.repo.path(), repo.path());
    }

    #[test]
    fn can_open_workspace() {
        let root_repo = TestRepo::new().unwrap();
        let workspace_dir = TempDir::new().unwrap();

        root_repo
            .jj()
            .args(["workspace", "add"])
            .arg(workspace_dir.path())
            .run()
            .unwrap();

        let workspace_repo = open_repo_chase_workspace(workspace_dir.path()).unwrap();
        assert_eq!(workspace_repo.path(), root_repo.repo.path());
    }
}
