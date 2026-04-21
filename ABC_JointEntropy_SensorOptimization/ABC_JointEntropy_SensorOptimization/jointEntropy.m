function H = jointEntropy(signals, bins, base)
%JOINTENTROPY Compute joint entropy H(X1, X2, ..., Xd) from multiple signals.
%
%   H = jointEntropy(signals, bins, base)
%
%   Inputs:
%       signals : N-by-D matrix or cell array of D vectors (same length)
%       bins    : scalar, vector, or cell array specifying bins
%                 - scalar: same number of bins for all signals
%                 - vector: per-signal bin counts [b1, b2, ..., bD]
%                 - cell: explicit bin edges {edges1, edges2, ...}
%       base    : logarithm base (2 for bits, e for nats, 10 for bans)
%
%   Output:
%       H : joint entropy (in bits, nats, or bans)
%
%   Example:
%       X = randn(1000, 3);
%       H = jointEntropy(X, 20, 2);
%       fprintf('Joint Entropy = %.4f bits\n', H);
%
%   ---------------------------------------------------------------------

    if nargin < 2 || isempty(bins)
        bins = 20;
    end
    if nargin < 3 || isempty(base)
        base = 2;
    end

    % Convert signals to numeric matrix
    if iscell(signals)
        X = cell2mat(signals(:)');
    else
        X = signals;
    end

    if ~ismatrix(X)
        error('signals must be N-by-D or a cell array of D same-length vectors.');
    end
    [N, D] = size(X);

    % === Step 1: Build bin edges ===
    edges = cell(1, D);

    if isscalar(bins)
        % same number of bins for all signals
        for d = 1:D
            edges{d} = linspace(min(X(:,d)), max(X(:,d)), bins + 1);
        end
    elseif isnumeric(bins) && isvector(bins) && numel(bins) == D
        % different bin counts per signal
        for d = 1:D
            edges{d} = linspace(min(X(:,d)), max(X(:,d)), bins(d) + 1);
        end
    elseif iscell(bins) && numel(bins) == D
        % explicit bin edges provided
        edges = bins;
    else
        error('Invalid "bins" input: must be scalar, vector of length D, or cell array of length D.');
    end

    % === Step 2: Discretize each signal ===
    idx = nan(N, D);
    for d = 1:D
        idx(:, d) = discretize(X(:, d), edges{d});
    end

    % Remove NaNs (out-of-range samples)
    valid = all(~isnan(idx), 2);
    idx = idx(valid, :);
    if isempty(idx)
        H = 0;
        return;
    end

    % === Step 3: Sparse counting of unique combinations ===
    [~, ~, ic] = unique(idx, 'rows');
    counts = accumarray(ic, 1);
    p = counts / sum(counts);
    p = p(p > 0);

    % === Step 4: Compute entropy ===
    switch base
        case 2
            logp = log2(p);
        case 10
            logp = log10(p);
        otherwise
            logp = log(p); % natural log
    end

    H = -sum(p .* logp);
end