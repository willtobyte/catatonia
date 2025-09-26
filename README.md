
```shell
gh auth refresh -h github.com -s read:packages -s write:packages -s read:org
```

```shell
echo "$(gh auth token)" | docker login ghcr.io -u skhaz --password-stdin
```
