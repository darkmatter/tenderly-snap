/**
 * Gatsby Node APIs for the site workspace.
 *
 * Upstream has no gatsby-node, so the snap origin read in src/config/snap.ts
 * (`process.env.SNAP_ORIGIN ?? 'local:http://localhost:8080'`) is never inlined
 * into the browser bundle — a hosted build would silently fall back to the
 * local-dev default. Define it explicitly at build time so a deployed site can
 * point MetaMask at the npm-published snap, e.g.
 *
 *   SNAP_ORIGIN=npm:@tenderly/metamask-snap yarn workspace ...-ui build
 *
 * When SNAP_ORIGIN is unset (local dev), the value collapses to the literal
 * `undefined` token, preserving the localhost fallback.
 */
import type { GatsbyNode } from 'gatsby';
import webpack from 'webpack';

export const onCreateWebpackConfig: GatsbyNode['onCreateWebpackConfig'] = ({
  actions,
}) => {
  actions.setWebpackConfig({
    plugins: [
      new webpack.DefinePlugin({
        'process.env.SNAP_ORIGIN':
          JSON.stringify(process.env.SNAP_ORIGIN) || 'undefined',
      }),
    ],
  });
};
