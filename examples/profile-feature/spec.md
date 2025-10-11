# Feature: User Profile Editing

## Metadata
**Workspace**: frontend
**Type**: feature

## Outcome
Users can view and edit their profile information (name, email, bio, avatar) with proper validation and error handling.

## User Story
As a registered user
I want to view and update my profile information
So that I can keep my account details current and personalized

## Context
**Current**: Users can view their profile but cannot edit any information. Profile data is read-only.
**Desired**: Full CRUD capabilities for user profile with form validation, error handling, and success feedback.
**Examples**:
- Similar pattern in Settings component (`src/components/Settings.tsx`) for form handling
- API pattern follows existing REST endpoints (`src/api/users.ts`)
- Validation similar to registration form (`src/components/Auth/Register.tsx`)

## Technical Requirements

### Frontend
- Profile edit form with fields:
  - Full Name (required, 2-50 characters)
  - Email (required, valid email format)
  - Bio (optional, max 500 characters)
  - Avatar URL (optional, valid URL)
- Real-time validation feedback
- Loading states during API calls
- Success/error toast notifications
- Cancel button to discard changes
- Dirty form detection (warn on navigation if unsaved)

### Backend API
- GET `/api/users/:id/profile` - Fetch user profile
- PUT `/api/users/:id/profile` - Update profile
- Validation:
  - Email uniqueness check (if changed)
  - Sanitize bio text (XSS prevention)
  - Avatar URL format validation
- Return updated profile on success

### Data Model
```typescript
interface UserProfile {
  id: string
  fullName: string
  email: string
  bio?: string
  avatarUrl?: string
  updatedAt: Date
}
```

### Testing
- Unit tests for validation logic
- Integration tests for API endpoints
- E2E test for complete edit workflow

## Validation Criteria
- [ ] User can view current profile information
- [ ] All form fields populate with existing data
- [ ] Real-time validation shows errors before submission
- [ ] Invalid email format is rejected
- [ ] Bio character count shows remaining characters
- [ ] Success message appears after save
- [ ] Error message appears if API fails
- [ ] Cancel button discards unsaved changes
- [ ] Form warns before navigating away with unsaved changes
- [ ] Updated data persists and displays correctly after page refresh
- [ ] Email uniqueness is enforced (different from other users)
- [ ] Avatar URL displays preview when valid URL entered

## Edge Cases
- Email changed to existing user's email → Show "Email already in use" error
- Network timeout during save → Show retry option
- Very long bio text → Truncate with character counter
- Invalid avatar URL → Show placeholder/default avatar
- Concurrent edits → Last write wins (or implement optimistic locking)

## References
- Form validation library: Zod or Yup (check existing dependencies)
- Toast notifications: React Hot Toast or similar
- API client: Axios or Fetch (match existing patterns)
- Similar form patterns: `src/components/Auth/Register.tsx`
- User API endpoints: `src/api/users.ts`

## Success Metrics
- Form validation prevents invalid submissions
- API response time < 500ms for profile updates
- Zero console errors during profile edit workflow
- All E2E tests pass
