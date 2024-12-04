name: Zero-IPK

on:
  push:
    paths:
      - '.github/workflows/Zero-IPK.yml'
      - 'package.sh'
  schedule:
    - cron: 0 */4 * * *
  repository_dispatch:
  workflow_dispatch:
    inputs:
      packages:
        description: 'packages'
        required: false
        default: 'false'	

jobs:
  job_Zero:
    if: github.event.repository.owner.id == github.event.sender.id || ! github.event.sender.id
    runs-on: ubuntu-latest

    name: Update OpenWrt Package
    strategy:
      fail-fast: false
      matrix:
        target: [main]
        
    steps:
    - name: Checkout
      uses: actions/checkout@main
      with:
        fetch-depth: 0

    - name: Initialization environment
      run : |
        git config --global user.email "oppen3218@users.noreply.github.com"
        git config --global user.name "actions-user"
        sudo timedatectl set-timezone "Asia/Shanghai"
        
    - name: Clone packages
      run: |
        cd $GITHUB_WORKSPACE
        chmod +x .github/diy/package.sh
        git clone -b main https://github.com/oppen321/Zero-package.git ${{matrix.target}}
        cd ${{matrix.target}}
        git rm -r --cache * >/dev/null 2>&1 &
        rm -rf `find ./* -maxdepth 0 -type d ! -name "commit"` >/dev/null 2>&1
        $GITHUB_WORKSPACE/.github/diy/package.sh
        bash /$GITHUB_WORKSPACE/.github/diy/convert_translation.sh
        bash /$GITHUB_WORKSPACE/.github/diy/create_acl_for_luci.sh -a
        bash /$GITHUB_WORKSPACE/.github/diy/Modify.sh

    - name: Upload
      env: 
        ACCESS_TOKEN: ${{ secrets.TOKEN_OPPEN321 }}
      run: |
        cd $GITHUB_WORKSPACE/${{matrix.target}}
        if git status --porcelain | grep .; then
          git add .
          git commit -am "update $(date '+%Y-%m-%d %H:%M:%S')"
          git push --quiet "https://${{ secrets.TOKEN_OPPEN321 }}@github.com/oppen321/Zero-package.git" HEAD:main
        else
          echo "nothing to commit"
          exit 0
        fi || exit 0

    - name: Delete workflow runs
      uses: Mattraks/delete-workflow-runs@main
      with:
        retain_days: 1
        keep_minimum_runs: 1
