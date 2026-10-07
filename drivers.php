<?php
require __DIR__ . '/includes/bootstrap.php';
require_permission('drivers.view');

$pdo = db();
ensure_runtime_schema();
$summary = growth_count_summary();
$rows = $pdo->query(
    "SELECT g.*, COALESCE(u.email, 'System') AS updated_by_email
     FROM daily_growth_counts g
     LEFT JOIN users u ON u.id = g.updated_by
     ORDER BY g.activity_date DESC
     LIMIT 60"
)->fetchAll();

$title = 'Registration Counts';
$active = 'drivers';
include __DIR__ . '/includes/header.php';
?>

<section class="section-toolbar registration-page-head reveal">
    <div>
        <p class="eyebrow">Count-only growth tracking</p>
        <h2>Customer &amp; driver registrations</h2>
        <p class="muted">Maintain daily registration totals without storing customer or driver personal details.</p>
    </div>
    <?php if (can('drivers.create')): ?>
        <button class="btn btn-primary" data-modal-open="growthCountModal" id="new-growth-count">
            <i data-lucide="plus"></i>
            Add daily count
        </button>
    <?php endif; ?>
</section>

<section class="count-kpi-grid registration-kpis reveal stagger-1" aria-label="Registration summary">
    <article class="count-kpi customer">
        <span class="metric-icon violet"><i data-lucide="user-round-plus"></i></span>
        <div>
            <small>Customers today</small>
            <strong><?= number_format($summary['today_customers']) ?></strong>
            <p><?= e(date('d M Y', strtotime($summary['today_date']))) ?></p>
        </div>
    </article>
    <article class="count-kpi driver">
        <span class="metric-icon blue"><i data-lucide="car-front"></i></span>
        <div>
            <small>Drivers today</small>
            <strong><?= number_format($summary['today_drivers']) ?></strong>
            <p><?= e(date('d M Y', strtotime($summary['today_date']))) ?></p>
        </div>
    </article>
    <article class="count-kpi customer">
        <span class="metric-icon violet"><i data-lucide="history"></i></span>
        <div>
            <small>Customers yesterday</small>
            <strong><?= number_format($summary['yesterday_customers']) ?></strong>
            <p><?= e(date('d M Y', strtotime($summary['yesterday_date']))) ?></p>
        </div>
    </article>
    <article class="count-kpi driver">
        <span class="metric-icon cyan"><i data-lucide="history"></i></span>
        <div>
            <small>Drivers yesterday</small>
            <strong><?= number_format($summary['yesterday_drivers']) ?></strong>
            <p><?= e(date('d M Y', strtotime($summary['yesterday_date']))) ?></p>
        </div>
    </article>
    <article class="count-kpi total">
        <span class="metric-icon success"><i data-lucide="users-round"></i></span>
        <div>
            <small>Total customers</small>
            <strong><?= number_format($summary['total_customers']) ?></strong>
            <p><?= number_format($summary['week_customers']) ?> in last 7 days</p>
        </div>
    </article>
    <article class="count-kpi total">
        <span class="metric-icon indigo"><i data-lucide="badge-check"></i></span>
        <div>
            <small>Total drivers</small>
            <strong><?= number_format($summary['total_drivers']) ?></strong>
            <p><?= number_format($summary['week_drivers']) ?> in last 7 days</p>
        </div>
    </article>
</section>

<section class="panel registration-ledger-panel reveal stagger-2">
    <div class="panel-heading registration-ledger-heading">
        <div>
            <p class="eyebrow">Daily ledger</p>
            <h3>Registration counts</h3>
            <p class="muted">One record per date. Saving the same date updates that day's totals instead of creating a duplicate.</p>
        </div>
        <span class="status-chip on-track"><i data-lucide="shield-check"></i>Count only</span>
    </div>

    <div class="table-wrap registration-ledger-wrap">
        <table class="registration-ledger-table">
            <thead>
                <tr>
                    <th>Date</th>
                    <th class="numeric">Customers</th>
                    <th class="numeric">Drivers</th>
                    <th class="numeric">Combined</th>
                    <th>Last update</th>
                    <th class="actions-col">Actions</th>
                </tr>
            </thead>
            <tbody>
            <?php if (!$rows): ?>
                <tr>
                    <td colspan="6">
                        <div class="empty-state registration-empty">
                            <i data-lucide="bar-chart-3"></i>
                            <h4>No daily counts yet</h4>
                            <p>Add today's or yesterday's totals to begin.</p>
                        </div>
                    </td>
                </tr>
            <?php else: ?>
                <?php foreach ($rows as $r):
                    $customers = (int)$r['customers_registered'];
                    $drivers = (int)$r['drivers_registered'];
                    $payload = [
                        'id' => (int)$r['id'],
                        'activity_date' => $r['activity_date'],
                        'customers_registered' => $customers,
                        'drivers_registered' => $drivers,
                    ];
                ?>
                    <tr>
                        <td>
                            <div class="ledger-date-cell">
                                <span class="ledger-date-icon"><i data-lucide="calendar-days"></i></span>
                                <div>
                                    <strong><?= e(date('D, d M Y', strtotime($r['activity_date']))) ?></strong>
                                    <small><?= e(date('l', strtotime($r['activity_date']))) ?></small>
                                </div>
                            </div>
                        </td>
                        <td class="numeric"><span class="ledger-number customer-number"><?= number_format($customers) ?></span></td>
                        <td class="numeric"><span class="ledger-number driver-number"><?= number_format($drivers) ?></span></td>
                        <td class="numeric"><strong class="ledger-combined"><?= number_format($customers + $drivers) ?></strong></td>
                        <td>
                            <div class="ledger-updated">
                                <strong><?= e(format_datetime($r['updated_at'], 'd M, h:i A')) ?></strong>
                                <small><?= e($r['updated_by_email']) ?></small>
                            </div>
                        </td>
                        <td class="actions-col">
                            <div class="ledger-actions">
                                <?php if (can('drivers.edit')): ?>
                                    <button class="icon-btn sm ledger-action" type="button" title="Edit daily count" aria-label="Edit daily count" data-growth-edit='<?= e(json_encode($payload, JSON_UNESCAPED_SLASHES)) ?>'>
                                        <i data-lucide="pencil"></i>
                                    </button>
                                    <form method="post" action="<?= e(url('handlers/growth-count-delete.php')) ?>">
                                        <?= csrf_field() ?>
                                        <input type="hidden" name="id" value="<?= (int)$r['id'] ?>">
                                        <button class="icon-btn sm danger-text ledger-action" type="submit" title="Delete daily count" aria-label="Delete daily count" data-confirm="Delete counts for <?= e(date('d M Y', strtotime($r['activity_date']))) ?>?">
                                            <i data-lucide="trash-2"></i>
                                        </button>
                                    </form>
                                <?php else: ?>
                                    <span class="muted">Read only</span>
                                <?php endif; ?>
                            </div>
                        </td>
                    </tr>
                <?php endforeach; ?>
            <?php endif; ?>
            </tbody>
        </table>
    </div>
</section>

<div class="modal" id="growthCountModal" aria-hidden="true">
    <div class="modal-card compact-modal">
        <button class="modal-close" data-modal-close><i data-lucide="x"></i></button>
        <p class="eyebrow">Daily registration input</p>
        <h3 id="growthCountTitle">Add daily count</h3>
        <p class="muted">Only numbers are stored. No personal customer or driver information is needed.</p>
        <form class="form-grid" method="post" action="<?= e(url('handlers/growth-count-save.php')) ?>">
            <?= csrf_field() ?>
            <input type="hidden" name="id" id="growthCountId">
            <label class="span-2">Registration date
                <input type="date" name="activity_date" id="growthCountDate" value="<?= e($summary['today_date']) ?>" required>
            </label>
            <label>Customers registered
                <input type="number" name="customers_registered" id="growthCustomers" min="0" max="1000000" value="0" required>
            </label>
            <label>Drivers registered
                <input type="number" name="drivers_registered" id="growthDrivers" min="0" max="1000000" value="0" required>
            </label>
            <div class="count-preview span-2">
                <span><i data-lucide="info"></i></span>
                <p>Use this form for <strong>today</strong>, <strong>yesterday</strong>, or any historical date. Totals update automatically on Admin and Public dashboards.</p>
            </div>
            <div class="form-actions span-2">
                <button type="button" class="btn btn-soft" data-modal-close>Cancel</button>
                <button class="btn btn-primary"><i data-lucide="save"></i>Save counts</button>
            </div>
        </form>
    </div>
</div>

<?php include __DIR__ . '/includes/footer.php'; ?>
