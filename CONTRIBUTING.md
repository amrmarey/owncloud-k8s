# Contributing to OwnCloud Kubernetes Deployment

Thank you for your interest in contributing to this project! 🎉

## How to Contribute

### Reporting Issues

If you find a bug or have a suggestion:

1. Check if the issue already exists in the [Issues](https://github.com/amrmarey/owncloud-k8s/issues)
2. If not, create a new issue with:
   - Clear description of the problem or suggestion
   - Steps to reproduce (for bugs)
   - Expected vs actual behavior
   - Environment details (Kubernetes version, cloud provider, etc.)

### Submitting Changes

1. **Fork the repository**
   ```bash
   git clone https://github.com/amrmarey/owncloud-k8s.git
   cd owncloud-k8s
   ```

2. **Create a feature branch**
   ```bash
   git checkout -b feature/your-feature-name
   ```

3. **Make your changes**
   - Follow the existing code style and structure
   - Test your changes thoroughly
   - Update documentation if needed

4. **Commit your changes**
   ```bash
   git add .
   git commit -m "Add: brief description of your changes"
   ```

5. **Push to your fork**
   ```bash
   git push origin feature/your-feature-name
   ```

6. **Open a Pull Request**
   - Provide a clear description of your changes
   - Reference any related issues
   - Ensure all tests pass

## Development Guidelines

### Project Structure

- `kind/` - KIND (local development) configurations
- `production/` - Production deployment configurations
- `docs/` - Documentation files
- `archive/` - Legacy/archived files

### Coding Standards

- **YAML files**: Use 2-space indentation
- **Scripts**: Use shellcheck for bash scripts
- **Documentation**: Use Markdown with proper formatting
- **Secrets**: Never commit real secrets or credentials

### Testing

Before submitting a PR:

1. Test with KIND locally:
   ```bash
   ./kind/scripts/deploy-kind.sh
   ```

2. Verify all pods are running:
   ```bash
   kubectl get pods -n owncloud
   ```

3. Check for any errors in logs

### Documentation

- Update README.md if adding new features
- Add comments to complex configurations
- Update relevant documentation in `docs/`

## Code of Conduct

- Be respectful and inclusive
- Provide constructive feedback
- Help others learn and grow

## Questions?

Feel free to open an issue for questions or reach out via:
- **GitHub**: [amrmarey](https://github.com/amrmarey/owncloud-k8s)
- **Email**: [amr.marey@msn.com](mailto:amr.marey@msn.com)

Thank you for contributing! 🙏
