# GitHub Pages Setup Guide

This guide will help you set up the GitHub Pages site for Universal Manifestor.

## Quick Setup

### 1. Enable GitHub Pages

1. Go to your repository on GitHub
2. Click on **Settings** tab
3. In the left sidebar, click on **Pages**
4. Under "Source", select:
   - **Branch**: `main`
   - **Folder**: `/docs`
5. Click **Save**

### 2. Wait for Deployment

GitHub will deploy your site at:
```
https://noktirnal42.github.io/universal_manifestor
```

It may take a few minutes for the site to be available.

### 3. Verify Your Site

Visit the URL above to see your live site. You should see:
- Universal Manifestor branding
- Four mode cards (Focus, Align, Manifest, Universe)
- Feature sections
- Download CTA

## Custom Domain (Optional)

If you want to use a custom domain (e.g., `universalmanifestor.app`):

1. Go to **Settings** → **Pages**
2. Under "Custom domain", enter your domain
3. Click **Save**
4. Update your DNS records to point to GitHub Pages

### DNS Configuration

For a custom domain, add these records to your DNS provider:

```
Type: A
Name: @
Value: 185.199.108.153
TTL: 3600

Type: A
Name: @
Value: 185.199.109.153
TTL: 3600

Type: A
Name: @
Value: 185.199.110.153
TTL: 3600

Type: A
Name: @
Value: 185.199.111.153
TTL: 3600

Type: CNAME
Name: www
Value: noktirnal42.github.io
TTL: 3600
```

## File Structure

The GitHub Pages site uses the following structure:

```
docs/
├── index.html          # Main landing page
├── support.html        # Support page
├── assets/
│   ├── AppIcon.png     # App icon for branding
│   └── README.md       # Asset documentation
└── README.md           # Documentation index
```

## Updating the Site

To update the GitHub Pages site:

1. Make changes to files in the `docs/` folder
2. Commit changes: `git commit -am "Update site"`
3. Push to GitHub: `git push origin main`
4. GitHub will automatically redeploy

## Troubleshooting

### Site not loading

- Check that you selected the correct branch and folder
- Wait a few minutes for deployment to complete
- Check the **Actions** tab for deployment status

### Images not showing

- Verify image paths are correct (relative to docs folder)
- Check that images are in the repository
- Ensure file extensions match (case-sensitive)

### Styles not applying

- Check that CSS is properly linked in HTML
- Verify the stylesheet paths are correct
- Clear browser cache and reload

## App Store Connect Requirements

For App Store Connect distribution, you'll need:

### Required Pages

1. **Privacy Policy** - Required for all apps
2. **Terms of Service** - Recommended
3. **Support URL** - Can use the GitHub Pages support page
4. **Marketing URL** (optional) - Can use the main GitHub Pages site

### Example URLs for App Store Connect

``````
Privacy Policy URL: https://noktirnal42.github.io/universal_manifestor/privacy.html
Terms of Service URL: https://noktirnal42.github.io/universal_manifestor/terms.html
Support URL: https://noktirnal42.github.io/universal_manifestor/support.html
Marketing URL: https://noktirnal42.github.io/universal_manifestor/
``````

## Creating Privacy Policy & Terms Pages

Create `privacy.html` and `terms.html` in the `docs/` folder with appropriate legal content.

### Privacy Policy Template

Key points to include:
- What data you collect (if any)
- How you use the data
- Data storage and security
- Third-party services (if any)
- User rights
- Contact information

### Terms of Service Template

Key points to include:
- Acceptable use
- Intellectual property
- Disclaimers
- Limitation of liability
- Termination
- Contact information

## Next Steps

1. ✅ Enable GitHub Pages
2. ✅ Verify site is live
3. ✅ Customize content as needed
4. ✅ Add privacy policy and terms pages
5. ✅ Update App Store Connect with URLs
6. ✅ Share your site!

## Resources

- [GitHub Pages Documentation](https://docs.github.com/en/pages)
- [GitHub Pages Examples](https://github.com/collections/github-pages-examples)
- [HTML5 Boilerplate](https://html5boilerplate.com/)

---

**Need help?** Check the [main README](../README.md) or contact [support@universalmanifestor.app](mailto:support@universalmanifestor.app)
