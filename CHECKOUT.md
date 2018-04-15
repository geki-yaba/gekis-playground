http://stackoverflow.com/questions/600079/is-there-any-way-to-clone-a-git-repositorys-sub-directory-only/13738951#13738951

What you are trying to do is called a sparse checkout, and that feature was added in git 1.7.0 (Feb. 2012). The steps to do a sparse clone are as follows:

```bash
mkdir <repo>
cd <repo>
git init
git remote add -f origin <url>
```

This creates an empty repository with your remote, and fetches all objects but doesn't check them out. Then do:

```bash
git config core.sparseCheckout true
```

Now you need to define which files/folders you want to actually check out. This is done by listing them in .git/info/sparse-checkout, eg:

```bash
echo "some/dir/" >> .git/info/sparse-checkout
echo "another/sub/tree" >> .git/info/sparse-checkout
```

Last but not least, update your empty repo with the state from the remote:

```bash
git checkout -B master origin/master
```
